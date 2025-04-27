import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/rtl_scaffold.dart';
import '../../auth/providers/auth_provider.dart' as AuthProvider;

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isSubmitting = false;
  bool _hasChanges = false;

  Future<bool> _confirmExit() async {
    if (!_hasChanges) return true;
    
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد الخروج'),
        content: Text('هل أنت متأكد من الخروج؟ سيتم فقدان البيانات غير المحفوظة.'),
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
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider.AuthProvider>(context);
    final user = authProvider.user;
    final userData = authProvider.userData;

    return RTLScaffold(
      title: 'الدعم',
      showBackButton: true,
      confirmOnBack: _hasChanges,
      fallbackRoute: '/home',
      confirmationMessage: 'هل أنت متأكد من الخروج؟ سيتم فقدان البيانات غير المحفوظة.',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: FormBuilder(
          key: _formKey,
          initialValue: {
            'name': userData?['name'] ?? '',
            'email': user?.email ?? '',
          },
          onChanged: () {
            // Set flag to true when user starts changing form values
            if (!_hasChanges && (_formKey.currentState?.fields['subject']?.value != null || 
                _formKey.currentState?.fields['description']?.value != null)) {
              setState(() {
                _hasChanges = true;
              });
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'هل تواجه مشكلة؟ أخبرنا بها',
                style: Theme.of(context).textTheme.displaySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Name Field (Read-only)
              FormBuilderTextField(
                name: 'name',
                decoration: InputDecoration(
                  labelText: 'الاسم',
                  filled: true,
                  fillColor: AppTheme.greyColor,
                ),
                readOnly: true,
              ),
              const SizedBox(height: 16),
              
              // Email Field (Read-only)
              FormBuilderTextField(
                name: 'email',
                decoration: InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  filled: true,
                  fillColor: AppTheme.greyColor,
                ),
                readOnly: true,
              ),
              const SizedBox(height: 16),
              
              // Subject Field
              FormBuilderTextField(
                name: 'subject',
                decoration: InputDecoration(
                  labelText: 'الموضوع',
                  hintText: 'أدخل موضوع المشكلة',
                ),
                validator: FormBuilderValidators.required(errorText: 'هذا الحقل مطلوب'),
              ),
              const SizedBox(height: 16),
              
              // Issue Description
              FormBuilderTextField(
                name: 'description',
                decoration: InputDecoration(
                  labelText: 'وصف المشكلة',
                  hintText: 'اشرح المشكلة بالتفصيل',
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(errorText: 'هذا الحقل مطلوب'),
                  FormBuilderValidators.minLength(20, errorText: 'يرجى توضيح المشكلة بشكل مفصل (20 حرف على الأقل)'),
                ]),
              ),
              const SizedBox(height: 24),
              
              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitSupportRequest,
                child: _isSubmitting
                    ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text('إرسال'),
              ),
              const SizedBox(height: 16),
              
              // Support Contact Information
              Card(
                color: AppTheme.greyColor,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'معلومات التواصل',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.email, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          Text('support@abayadesign.com'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.phone, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          Text('0501234567'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.access_time, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          Text('متوفرون 24/7'),
                        ],
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

  Future<void> _submitSupportRequest() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() {
        _isSubmitting = true;
        _hasChanges = false;
      });
      
      final values = _formKey.currentState!.value;
      final user = FirebaseAuth.instance.currentUser;
      
      try {
        // Save to Firebase Support collection
        await FirebaseFirestore.instance.collection('Support').add({
          'userId': user?.uid,
          'name': values['name'],
          'email': values['email'],
          'subject': values['subject'],
          'description': values['description'],
          'status': 'open',
          'timestamp': FieldValue.serverTimestamp(),
        });
        
        if (mounted) {
          // Clear the form
          _formKey.currentState?.reset();
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم إرسال طلب الدعم بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل إرسال طلب الدعم. الرجاء المحاولة مرة أخرى.')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      }
    }
  }
}