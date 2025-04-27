// lib/features/abayas/screens/abaya_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/abayas_provider.dart';
import '../../measurements/providers/measurements_provider.dart';

class AbayaSelectionScreen extends StatefulWidget {
  const AbayaSelectionScreen({super.key});

  @override
  State<AbayaSelectionScreen> createState() => _AbayaSelectionScreenState();
}

class _AbayaSelectionScreenState extends State<AbayaSelectionScreen> {
  Set<String> _selectedAbayas = {};
  bool _isLoading = true;
  String? _errorMessage;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    // Schedule the loading operation after the build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAbayas();
    });
  }

  Future<void> _loadAbayas() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isRetrying = false;
    });
    
    try {
      // Get the user's body shape first
      final measurementsProvider = Provider.of<MeasurementsProvider>(context, listen: false);
      final bodyShape = measurementsProvider.bodyShape;
      
      // Then load recommended abayas based on that body shape
      final abayasProvider = Provider.of<AbayasProvider>(context, listen: false);
      await abayasProvider.loadRecommendedAbayas(bodyShape: bodyShape);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = abayasProvider.errorMessage;
          _selectedAbayas = Set<String>.from(abayasProvider.selectedAbayaIds);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
          
          // Handle specific error messages
          if (e.toString().contains('timeout')) {
            _errorMessage = 'انتهت مهلة الاتصال. قد يستغرق بدء تشغيل الخادم بعض الوقت، يرجى المحاولة مرة أخرى.';
          }
        });
      }
    }
  }

  void _toggleSelection(String abayaId) {
    setState(() {
      if (_selectedAbayas.contains(abayaId)) {
        _selectedAbayas.remove(abayaId);
      } else {
        _selectedAbayas.add(abayaId);
      }
    });
    
    Provider.of<AbayasProvider>(context, listen: false)
        .updateSelectedAbayas(_selectedAbayas);
  }
  
  // Navigate directly to home
  void _navigateToHome() {
    context.go('/home');
  }

  // Simple function to confirm exit
  Future<bool> _confirmExit() async {
    // No need to confirm if no abayas are selected
    if (_selectedAbayas.isEmpty) return true;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد الخروج'),
        content: Text('هل أنت متأكد من الخروج؟ سيتم فقدان العبايات المختارة.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('خروج', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final abayasProvider = Provider.of<AbayasProvider>(context);
    final measurementsProvider = Provider.of<MeasurementsProvider>(context);
    final bodyShape = measurementsProvider.bodyShape;
    
    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await _confirmExit();
        if (shouldExit) {
          _navigateToHome();
        }
        return false; // Always return false to prevent default back behavior
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('اختيار العبايات'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () async {
              if (await _confirmExit()) {
                _navigateToHome();
              }
            },
          ),
          actions: [
            if (_selectedAbayas.isNotEmpty)
              TextButton(
                onPressed: () => context.go('/summary'),
                child: Text(
                  'التالي',
                  style: TextStyle(color: AppTheme.primaryColor),
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'اختاري العبايات المناسبة لشكل جسمك',
                    style: Theme.of(context).textTheme.displaySmall,
                    textAlign: TextAlign.center,
                  ),
                  if (bodyShape != null) 
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'شكل الجسم: $bodyShape',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                  // API information note
                  if (!_isLoading && abayasProvider.recommendedAbayas.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'تم تحميل العبايات المناسبة لشكل جسمك',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Error message if any
            if (_errorMessage != null || abayasProvider.errorMessage != null)
              Container(
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  children: [
                    Text(
                      _errorMessage ?? abayasProvider.errorMessage ?? 'حدث خطأ',
                      style: TextStyle(color: Colors.red.shade800),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12),
                    _isRetrying 
                      ? SpinKitCircle(color: AppTheme.primaryColor, size: 24)
                      : ElevatedButton(
                          onPressed: () {
                            setState(() => _isRetrying = true);
                            _loadAbayas();
                          },
                          child: Text('إعادة المحاولة'),
                        ),
                  ],
                ),
              ),
            
            Expanded(
              child: _isLoading
                  ? Center(child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SpinKitCircle(color: AppTheme.primaryColor, size: 40),
                        SizedBox(height: 16),
                        Text('جاري تحميل العبايات المناسبة...'),
                        SizedBox(height: 8),
                        Text(
                          'قد يستغرق الأمر بضع دقائق في المرة الأولى',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ))
                  : abayasProvider.recommendedAbayas.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'لا توجد عبايات متاحة حالياً',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadAbayas,
                                child: Text('إعادة المحاولة'),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.7,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: abayasProvider.recommendedAbayas.length,
                          itemBuilder: (context, index) {
                            final abaya = abayasProvider.recommendedAbayas[index];
                            final isSelected = _selectedAbayas.contains(abaya.id);
                            
                            return GestureDetector(
                              onTap: () => _toggleSelection(abaya.id),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.accentColor
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: _buildAbayaImage(abaya.image1Url),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            abaya.model,
                                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '${abaya.fabric} - ${abaya.color}',
                                            style: Theme.of(context).textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'تم اختيار',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Text(
                          '${_selectedAbayas.length} عبايات',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _selectedAbayas.isEmpty
                          ? null
                          : () => context.go('/summary'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 48),
                      ),
                      child: Text('عرض الملخص'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAbayaImage(String imageUrl) {
    // Handle base64 images from the API
    if (imageUrl.startsWith('data:image')) {
      return Image.memory(
        Uri.parse(imageUrl).data!.contentAsBytes(),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading base64 image: $error');
          return Container(
            color: AppTheme.greyColor,
            child: Icon(Icons.broken_image, color: Colors.grey[600]),
          );
        },
      );
    }
    
    // Handle URL-based images
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Center(
        child: CircularProgressIndicator(),
      ),
      errorWidget: (context, url, error) {
        print('Image error: $error for URL: $url');
        return Container(
          color: AppTheme.greyColor,
          child: Icon(Icons.error, color: Colors.red),
        );
      },
      // Additional headers for potential CORS issues
      httpHeaders: {
        'Accept': '*/*',
      },
    );
  }
}