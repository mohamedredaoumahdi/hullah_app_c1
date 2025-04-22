// lib/features/auth/screens/register_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/direct_auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String _errorMessage = '';

  // Get the direct auth service
  final _authService = DirectAuthService.instance;

  Future<void> _handleRegister() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        // Extract form values
        final String name = _formKey.currentState!.value['name'] ?? '';
        final String email = _formKey.currentState!.value['email'] ?? '';
        final String password = _formKey.currentState!.value['password'] ?? '';
        final String phone = _formKey.currentState!.value['phone'] ?? '';
        final String heightStr = _formKey.currentState!.value['height'] ?? '';
        final double height = double.tryParse(heightStr) ?? 170.0;
        final DateTime dateOfBirth = _formKey.currentState!.value['dateOfBirth'] ?? DateTime.now();

        // Step 1: Create the auth user
        print('Creating auth user for $email');
        final User? user = await _authService.signUp(email, password);

        if (user == null) {
          throw Exception('Failed to create user account');
        }

        print('User created with ID: ${user.uid}');

        // Step 2: Now create the user profile
        print('Creating user profile for ${user.uid}');
        final success = await _authService.createUserProfile(
          userId: user.uid,
          name: name,
          email: email,
          phone: phone,
          height: height,
          dateOfBirth: dateOfBirth
        );

        if (!success) {
          throw Exception('Failed to create user profile');
        }

        print('Registration completed successfully');

        if (mounted) {
          // Navigate to home screen
          context.go('/home');
        }
      } catch (e) {
        print('Registration error: $e');
        
        if (mounted) {
          setState(() {
            _errorMessage = e.toString();
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل إنشاء الحساب: يرجى المحاولة مرة أخرى'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('إنشاء حساب'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: FormBuilder(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Error message display
                if (_errorMessage.isNotEmpty)
                  Container(
                    padding: EdgeInsets.all(10),
                    margin: EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                
                // Name Field
                FormBuilderTextField(
                  name: 'name',
                  decoration: InputDecoration(
                    labelText: 'الاسم الكامل',
                    hintText: 'أدخل اسمك الكامل',
                    prefixIcon: Icon(Icons.person, color: AppTheme.blackColor),
                  ),
                  validator: FormBuilderValidators.required(errorText: 'هذا الحقل مطلوب'),
                ),
                const SizedBox(height: 16),
                
                // Email Field
                FormBuilderTextField(
                  name: 'email',
                  decoration: InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    hintText: 'أدخل بريدك الإلكتروني',
                    prefixIcon: Icon(Icons.email, color: AppTheme.blackColor),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(errorText: 'هذا الحقل مطلوب'),
                    FormBuilderValidators.email(errorText: 'الرجاء إدخال بريد إلكتروني صحيح'),
                    (value) {
                      if (value != null && RegExp(r'[\u0600-\u06FF]').hasMatch(value)) {
                        return 'يرجى استخدام أحرف إنجليزية فقط';
                      }
                      return null;
                    },
                  ]),
                ),
                const SizedBox(height: 16),
                
                // Phone Field
                FormBuilderTextField(
                  name: 'phone',
                  decoration: InputDecoration(
                    labelText: 'رقم الهاتف',
                    hintText: '05XXXXXXXX',
                    prefixIcon: Icon(Icons.phone, color: AppTheme.blackColor),
                  ),
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(errorText: 'هذا الحقل مطلوب'),
                    (value) {
                      if (value == null || value.isEmpty) return null;
                      if (!value.startsWith('05')) {
                        return 'يجب أن يبدأ رقم الهاتف بـ 05';
                      }
                      if (value.length != 10) {
                        return 'يجب أن يكون رقم الهاتف 10 أرقام';
                      }
                      if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                        return 'يجب أن يحتوي على أرقام فقط';
                      }
                      return null;
                    },
                  ]),
                ),
                const SizedBox(height: 16),
                
                // Height Field
                FormBuilderTextField(
                  name: 'height',
                  decoration: InputDecoration(
                    labelText: 'الطول (سم)',
                    hintText: 'أدخل طولك بالسنتيمتر',
                    prefixIcon: Icon(Icons.height, color: AppTheme.blackColor),
                  ),
                  keyboardType: TextInputType.number,
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(errorText: 'هذا الحقل مطلوب'),
                    FormBuilderValidators.numeric(errorText: 'يجب أن يكون رقماً'),
                    (value) {
                      if (value == null || value.isEmpty) return null;
                      final height = double.tryParse(value);
                      if (height == null) return 'يجب أن يكون رقماً';
                      if (height < 100) return 'الحد الأدنى للطول 100 سم';
                      if (height > 250) return 'الرجاء إدخال طول صحيح';
                      return null;
                    },
                  ]),
                ),
                const SizedBox(height: 16),
                
                // Date of Birth Field
                FormBuilderDateTimePicker(
                  name: 'dateOfBirth',
                  decoration: InputDecoration(
                    labelText: 'تاريخ الميلاد',
                    hintText: 'اختر تاريخ ميلادك',
                    prefixIcon: Icon(Icons.calendar_today, color: AppTheme.blackColor),
                  ),
                  inputType: InputType.date,
                  firstDate: DateTime(1940),
                  lastDate: DateTime.now(),
                  validator: FormBuilderValidators.required(errorText: 'هذا الحقل مطلوب'),
                ),
                const SizedBox(height: 16),
                
                // Password Field
                FormBuilderTextField(
                  name: 'password',
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    hintText: 'أدخل كلمة المرور',
                    prefixIcon: Icon(Icons.lock, color: AppTheme.blackColor),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: AppTheme.blackColor,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                  textDirection: TextDirection.ltr,
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(errorText: 'هذا الحقل مطلوب'),
                    FormBuilderValidators.minLength(6, errorText: 'يجب أن تكون 6 أحرف على الأقل'),
                    (value) {
                      if (value != null && RegExp(r'[\u0600-\u06FF]').hasMatch(value)) {
                        return 'يرجى استخدام أحرف إنجليزية فقط';
                      }
                      return null;
                    },
                  ]),
                ),
                const SizedBox(height: 16),
                
                // Confirm Password Field
                FormBuilderTextField(
                  name: 'confirmPassword',
                  decoration: InputDecoration(
                    labelText: 'تأكيد كلمة المرور',
                    hintText: 'أعد إدخال كلمة المرور',
                    prefixIcon: Icon(Icons.lock_outline, color: AppTheme.blackColor),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        color: AppTheme.blackColor,
                      ),
                      onPressed: () {
                        setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                      },
                    ),
                  ),
                  obscureText: _obscureConfirmPassword,
                  textDirection: TextDirection.ltr,
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(errorText: 'هذا الحقل مطلوب'),
                    (value) {
                      if (value != _formKey.currentState?.fields['password']?.value) {
                        return 'كلمة المرور غير متطابقة';
                      }
                      return null;
                    },
                  ]),
                ),
                const SizedBox(height: 32),
                
                // Register Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  child: _isLoading
                      ? SpinKitCircle(color: Colors.white, size: 24)
                      : Text('إنشاء حساب'),
                ),
                const SizedBox(height: 16),
                
                // Login Link
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text(
                    'لديك حساب بالفعل؟ تسجيل الدخول',
                    style: TextStyle(color: AppTheme.primaryColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}