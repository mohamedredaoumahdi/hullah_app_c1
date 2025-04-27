import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';

/// A widget to diagnose image loading issues
/// Can be added to a debug menu or shown on long press of an image
class ImageDiagnosticWidget extends StatefulWidget {
  final String originalUrl;
  
  const ImageDiagnosticWidget({
    Key? key,
    required this.originalUrl,
  }) : super(key: key);

  @override
  State<ImageDiagnosticWidget> createState() => _ImageDiagnosticWidgetState();
}

class _ImageDiagnosticWidgetState extends State<ImageDiagnosticWidget> {
  late String _currentUrl;
  bool _isLoading = false;
  String? _errorMessage;
  bool _imageLoaded = false;
  
  @override
  void initState() {
    super.initState();
    _currentUrl = widget.originalUrl;
    _testImageLoading();
  }
  
  Future<void> _testImageLoading() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _imageLoaded = false;
    });
    
    try {
      // Test image loading
      final imageProvider = NetworkImage(_currentUrl);
      
      // Create image stream to test loading
      final ImageStream stream = imageProvider.resolve(ImageConfiguration.empty);
      
      final completer = Completer<void>();
      
      late ImageStreamListener listener;
      listener = ImageStreamListener(
        (ImageInfo info, bool synchronousCall) {
          // Success
          if (!completer.isCompleted) {
            completer.complete();
            stream.removeListener(listener);
            
            if (mounted) {
              setState(() {
                _imageLoaded = true;
                _isLoading = false;
              });
            }
          }
        },
        onError: (exception, stackTrace) {
          // Error
          if (!completer.isCompleted) {
            completer.completeError(exception);
            stream.removeListener(listener);
            
            if (mounted) {
              setState(() {
                _errorMessage = exception.toString();
                _isLoading = false;
              });
            }
          }
        },
      );
      
      stream.addListener(listener);
      
      // Set a timeout
      Future.delayed(Duration(seconds: 10), () {
        if (!completer.isCompleted) {
          completer.completeError('Timeout occurred');
          stream.removeListener(listener);
          
          if (mounted) {
            setState(() {
              _errorMessage = 'Timeout while loading image';
              _isLoading = false;
            });
          }
        }
      });
      
      await completer.future;
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }
  
  // Transform URL based on common patterns
  void _transformUrl(String format) {
    String newUrl = _currentUrl;
    
    switch (format) {
      case 'drive_thumbnail':
        if (_currentUrl.contains('drive.google.com')) {
          // Extract file ID using various patterns
          String? fileId;
          
          if (_currentUrl.contains('/file/d/')) {
            final regex = RegExp(r'file/d/([^/]+)');
            final match = regex.firstMatch(_currentUrl);
            fileId = match?.group(1);
          } else if (_currentUrl.contains('id=')) {
            final regex = RegExp(r'[?&]id=([^&]+)');
            final match = regex.firstMatch(_currentUrl);
            fileId = match?.group(1);
          }
          
          if (fileId != null) {
            newUrl = 'https://drive.google.com/thumbnail?id=$fileId&sz=w800';
          }
        }
        break;
      
      case 'drive_uc':
        if (_currentUrl.contains('drive.google.com')) {
          // Extract file ID using various patterns
          String? fileId;
          
          if (_currentUrl.contains('/file/d/')) {
            final regex = RegExp(r'file/d/([^/]+)');
            final match = regex.firstMatch(_currentUrl);
            fileId = match?.group(1);
          } else if (_currentUrl.contains('id=')) {
            final regex = RegExp(r'[?&]id=([^&]+)');
            final match = regex.firstMatch(_currentUrl);
            fileId = match?.group(1);
          }
          
          if (fileId != null) {
            newUrl = 'https://drive.google.com/uc?export=view&id=$fileId';
          }
        }
        break;
      
      case 'placeholder':
        // Replace with a guaranteed working placeholder
        newUrl = 'https://via.placeholder.com/400x600?text=Test+Image';
        break;
    }
    
    if (newUrl != _currentUrl) {
      setState(() {
        _currentUrl = newUrl;
      });
      _testImageLoading();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تشخيص تحميل الصور'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Original URL information
            Text(
              'الرابط الأصلي:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              width: double.infinity,
              child: Text(
                widget.originalUrl,
                style: TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
            SizedBox(height: 16),
            
            // Current URL being tested
            Text(
              'الرابط الحالي:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              width: double.infinity,
              child: Text(
                _currentUrl,
                style: TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
            SizedBox(height: 16),
            
            // URL transformation options
            Text(
              'تجربة تحويلات الرابط:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () => _transformUrl('drive_thumbnail'),
                  child: Text('تحويل إلى صورة مصغرة'),
                ),
                ElevatedButton(
                  onPressed: () => _transformUrl('drive_uc'),
                  child: Text('تحويل إلى رابط UC'),
                ),
                ElevatedButton(
                  onPressed: () => _transformUrl('placeholder'),
                  child: Text('استخدام صورة بديلة'),
                ),
              ],
            ),
            SizedBox(height: 24),
            
            // Image preview
            Text(
              'معاينة الصورة:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            Center(
              child: Container(
                width: 200,
                height: 260,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, color: Colors.red, size: 48),
                          SizedBox(height: 16),
                          Text(
                            'فشل تحميل الصورة',
                            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _currentUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / 
                                    loadingProgress.expectedTotalBytes!
                                  : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error, color: Colors.red, size: 48),
                                SizedBox(height: 16),
                                Text(
                                  'فشل تحميل الصورة',
                                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Text(
                                    error.toString(),
                                    style: TextStyle(color: Colors.red, fontSize: 12),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
              ),
            ),
            SizedBox(height: 24),
            
            // Status
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _imageLoaded ? Colors.green[100] : 
                       _errorMessage != null ? Colors.red[100] : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _imageLoaded ? Icons.check_circle : 
                    _errorMessage != null ? Icons.error : Icons.hourglass_top,
                    color: _imageLoaded ? Colors.green : 
                           _errorMessage != null ? Colors.red : Colors.grey,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _imageLoaded ? 'تم تحميل الصورة بنجاح' : 
                      _errorMessage != null ? 'فشل تحميل الصورة' : 'جاري التحميل...',
                      style: TextStyle(
                        color: _imageLoaded ? Colors.green[800] : 
                               _errorMessage != null ? Colors.red[800] : Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            
            // Retry button
            Center(
              child: ElevatedButton.icon(
                onPressed: _testImageLoading,
                icon: Icon(Icons.refresh),
                label: Text('إعادة المحاولة'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
