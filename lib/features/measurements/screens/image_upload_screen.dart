import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/measurements_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/widgets/loading_screen.dart';

class ImageUploadScreen extends StatefulWidget {
  const ImageUploadScreen({super.key});

  @override
  State<ImageUploadScreen> createState() => _ImageUploadScreenState();
}

class _ImageUploadScreenState extends State<ImageUploadScreen> {
  File? _selectedImage;
  bool _isLoading = false;
  String? _errorMessage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'فشل في اختيار الصورة';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في اختيار الصورة')),
      );
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;
    
    setState(() => _isLoading = true);
    
    // Show loading screen
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SpinKitCircle(color: AppTheme.primaryColor, size: 50),
                SizedBox(height: 20),
                Text(
                  'يتم التحليل...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'يرجى الانتظار بينما نقوم بتحليل الصورة. قد يستغرق الأمر بعض الوقت إذا كان الخادم يبدأ تشغيله.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final measurementsProvider = Provider.of<MeasurementsProvider>(context, listen: false);
      
      // Upload image to Firebase Storage (optional for backup)
      final ref = FirebaseStorage.instance
          .ref()
          .child('measurement_images')
          .child('${authProvider.user!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      await ref.putFile(_selectedImage!);
      final imageUrl = await ref.getDownloadURL();
      
      // Process image through API
      await measurementsProvider.saveImageAnalysisResults(_selectedImage!);
      
      if (mounted) {
        Navigator.pop(context); // Dismiss loading dialog
        context.go('/measurements/analysis');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss loading dialog
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
          if (e.toString().contains('timeout')) {
            _errorMessage = 'انتهت مهلة الاتصال. قد يستغرق بدء تشغيل الخادم بعض الوقت، يرجى المحاولة مرة أخرى.';
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage ?? 'فشل في تحليل الصورة. الرجاء المحاولة مرة أخرى.'),
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: 'حسناً',
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _confirmCancel() async {
    if (_selectedImage == null) {
      context.go('/home');
      return;
    }
    
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('تأكيد الإلغاء'),
          content: Text('هل أنت متأكدة من إلغاء العملية؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('لا'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('نعم', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
    
    if (result == true && mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('رفع صورة للقياسات'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: _confirmCancel,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'قم برفع صورة واضحة للجسم بالكامل لتحليل القياسات',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              if (_errorMessage != null)
                Container(
                  padding: EdgeInsets.all(12),
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade800),
                        textAlign: TextAlign.center,
                      ),
                      if (_errorMessage!.contains('timeout'))
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'يحتاج الخادم المستضاف إلى بضع دقائق للبدء إذا كان خاملاً. يرجى المحاولة مرة أخرى.',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.red.shade800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              
              Expanded(
                child: _selectedImage != null
                    ? Column(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => setState(() {
                              _selectedImage = null;
                              _errorMessage = null;
                            }),
                            icon: Icon(Icons.refresh),
                            label: Text('اختر صورة أخرى'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.greyColor,
                              foregroundColor: AppTheme.blackColor,
                            ),
                          ),
                        ],
                      )
                    : Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.primaryColor, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              size: 80,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'اختر صورة',
                              style: Theme.of(context).textTheme.displaySmall,
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _pickImage(ImageSource.camera),
                                  icon: Icon(Icons.camera_alt),
                                  label: Text('الكاميرا'),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton.icon(
                                  onPressed: () => _pickImage(ImageSource.gallery),
                                  icon: Icon(Icons.photo_library),
                                  label: Text('المعرض'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 24),
              
              ElevatedButton(
                onPressed: _selectedImage != null && !_isLoading ? _analyzeImage : null,
                child: _isLoading
                    ? SpinKitCircle(color: Colors.white, size: 24)
                    : Text('تحليل الصورة'),
              ),
              
              // API information note
              if (_selectedImage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'يتم استخدام خادم API مستضاف خارجياً لتحليل الصورة',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'قد يستغرق بدء تشغيل الخادم بضع دقائق إذا كان خاملاً',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.blue.shade800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}