import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() => _isLoading = true);
      
      final values = _formKey.currentState!.value;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      try {
        await authProvider.login(
          email: values['email'],
          password: values['password'],
        );
        
        if (mounted) {
          context.go('/home');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل تسجيل الدخول. الرجاء المحاولة مرة أخرى.')),
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: FormBuilder(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                Text(
                  'تسجيل الدخول',
                  style: Theme.of(context).textTheme.displayLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                
                // Email Field
                FormBuilderTextField(
                  name: 'email',
                  decoration: InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    hintText: 'أدخل بريدك الإلكتروني',
                    prefixIcon: Icon(Icons.email, color: AppTheme.blackColor, size: 28),
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
                
                // Password Field
                FormBuilderTextField(
                  name: 'password',
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    hintText: 'أدخل كلمة المرور',
                    prefixIcon: Icon(Icons.lock, color: AppTheme.blackColor, size: 28),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: AppTheme.blackColor,
                        size: 28,
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
                    (value) {
                      if (value != null && RegExp(r'[\u0600-\u06FF]').hasMatch(value)) {
                        return 'يرجى استخدام أحرف إنجليزية فقط';
                      }
                      return null;
                    },
                  ]),
                ),
                const SizedBox(height: 32),
                
                // Login Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? SpinKitCircle(color: Colors.white, size: 24)
                      : Text('تسجيل الدخول'),
                ),
                const SizedBox(height: 16),
                
                // Register Link
                TextButton(
                  onPressed: () => context.go('/register'),
                  child: Text(
                    'ليس لديك حساب؟ سجل الآن',
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