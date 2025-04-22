// lib/features/measurements/screens/image_upload_screen.dart

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
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في اختيار الصورة')),
      );
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;
    
    setState(() => _isLoading = true);
    
    // Show loading screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LoadingScreen(message: 'يتم التحليل...'),
      ),
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
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في تحليل الصورة. الرجاء المحاولة مرة أخرى.')),
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
                            onPressed: () => setState(() => _selectedImage = null),
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
            ],
          ),
        ),
      ),
    );
  }
}