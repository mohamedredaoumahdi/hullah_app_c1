// lib/features/measurements/screens/image_upload_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/rtl_scaffold.dart';
import '../providers/measurements_provider.dart';
import '../../auth/providers/auth_provider.dart';

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

  @override
  void initState() {
    super.initState();
    // Check if camera is available and open it automatically
    // Commented out for now, as it might not be desired behavior
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _pickImage(ImageSource.camera);
    // });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() => _isLoading = true);

      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85, // Slightly compressed for faster upload
        maxWidth: 1200, // Limit width for analysis
        preferredCameraDevice: CameraDevice.rear, // Prefer rear camera
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _errorMessage = null;
          _isLoading = false;
        });
      } else {
        // User canceled image picking
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'فشل في اختيار الصورة: ${e.toString()}';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل في اختيار الصورة. الرجاء المحاولة مرة أخرى.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;
    
    setState(() => _isLoading = true);
    
    // Show loading screen
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SpinKitCircle(color: AppTheme.primaryColor, size: 50),
                  SizedBox(height: 24),
                  Text(
                    'يتم تحليل الصورة...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'يرجى الانتظار بينما نقوم بتحليل الصورة.\nقد يستغرق الأمر بعض الوقت.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final measurementsProvider = Provider.of<MeasurementsProvider>(context, listen: false);
      
      // Upload image to Firebase Storage for backup
      String? imageUrl;
      try {
        // Only attempt this if the user is authenticated
        if (authProvider.user != null) {
          final ref = FirebaseStorage.instance
              .ref()
              .child('measurement_images')
              .child('${authProvider.user!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');
          
          await ref.putFile(_selectedImage!);
          imageUrl = await ref.getDownloadURL();
        }
      } catch (storageError) {
        // Log storage error but continue with analysis
        print('Warning: Failed to upload image to storage: $storageError');
      }
      
      // Process image through provider
      await Future.delayed(Duration(seconds: 1)); // Small delay for UI feedback
      await measurementsProvider.saveImageAnalysisResults(_selectedImage!);
      
      if (mounted) {
        // Dismiss loading dialog
        Navigator.pop(context);
        
        // Add a small delay before navigation
        await Future.delayed(Duration(milliseconds: 300));
        if (mounted) {
          context.go('/measurements/analysis');
        }
      }
    } catch (e) {
      if (mounted) {
        // Dismiss loading dialog
        Navigator.pop(context);
        
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
          if (e.toString().contains('timeout')) {
            _errorMessage = 'انتهت مهلة الاتصال. قد يستغرق بدء تشغيل الخادم بعض الوقت، يرجى المحاولة مرة أخرى.';
          }
        });
        
        _showErrorDialog();
      }
    }
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('خطأ في تحليل الصورة'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_errorMessage ?? 'حدث خطأ غير متوقع أثناء تحليل الصورة'),
              SizedBox(height: 16),
              Text(
                'يمكنك محاولة ما يلي:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• إعادة التقاط الصورة في إضاءة أفضل'),
              Text('• التأكد من وضوح الصورة وظهور الجسم كاملاً'),
              Text('• إدخال القياسات يدوياً بدلاً من الصورة'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('حسناً'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/measurements/input');
            },
            child: Text('إدخال القياسات يدوياً'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RTLScaffold(
      title: 'رفع صورة للقياسات',
      showBackButton: true,
      confirmOnBack: _selectedImage != null,
      fallbackRoute: '/measurements/instructions',
      confirmationMessage: 'هل أنت متأكدة من إلغاء العملية؟',
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'التقط صورة واضحة للجسم بالكامل لتحليل القياسات',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              if (_errorMessage != null && !_isLoading)
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
                      SizedBox(height: 8),
                      TextButton(
                        onPressed: () => setState(() => _errorMessage = null),
                        child: Text('إغلاق'),
                      ),
                    ],
                  ),
                ),
              
              Expanded(
                child: _isLoading && _selectedImage == null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SpinKitCircle(color: AppTheme.primaryColor, size: 40),
                            SizedBox(height: 16),
                            Text('جاري تحضير الكاميرا...'),
                          ],
                        ),
                      )
                    : _selectedImage != null
                        ? _buildSelectedImageView()
                        : _buildCameraOptions(),
              ),
              
              // Bottom buttons
              if (_selectedImage != null)
                Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: !_isLoading ? _analyzeImage : null,
                      icon: Icon(Icons.analytics),
                      label: Text('تحليل الصورة'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                      ),
                    ),
                    SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: !_isLoading 
                          ? () => setState(() => _selectedImage = null)
                          : null,
                      icon: Icon(Icons.refresh),
                      label: Text('إعادة التقاط الصورة'),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    OutlinedButton.icon(
                      onPressed: !_isLoading 
                          ? () => context.go('/measurements/input')
                          : null,
                      icon: Icon(Icons.edit),
                      label: Text('إدخال القياسات يدوياً'),
                    ),
                    SizedBox(height: 12),
                    TextButton(
                      onPressed: !_isLoading 
                          ? () => context.go('/measurements/instructions')
                          : null,
                      child: Text('العودة للتعليمات'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedImageView() {
    return Column(
      children: [
        Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.primaryColor, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                _selectedImage!,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        Text(
          'تأكد من ظهور الجسم بالكامل وبوضوح في الصورة',
          style: TextStyle(
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCameraOptions() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.5), width: 2),
        borderRadius: BorderRadius.circular(16),
        color: AppTheme.primaryColor.withOpacity(0.05),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_a_photo,
            size: 80,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 24),
          Text(
            'التقط صورة للجسم بالكامل',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'اختر مصدر الصورة:',
            style: TextStyle(
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSourceButton(
                icon: Icons.camera_alt,
                label: 'الكاميرا',
                onTap: () => _pickImage(ImageSource.camera),
              ),
              _buildSourceButton(
                icon: Icons.photo_library,
                label: 'المعرض',
                onTap: () => _pickImage(ImageSource.gallery),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 36,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}