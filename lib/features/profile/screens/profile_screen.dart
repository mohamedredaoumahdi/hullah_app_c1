import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userData = authProvider.userData ?? {};
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('صفحتي'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: _isEditing ? _saveProfile : () => setState(() => _isEditing = true),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: FormBuilder(
            key: _formKey,
            initialValue: {
              'name': userData['name'] ?? '',
              'phone': userData['phone'] ?? '',
              'height': userData['height']?.toString() ?? '',
              'dateOfBirth': userData['dateOfBirth']?.toDate() ?? DateTime.now(),
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Image Placeholder
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppTheme.greyColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.person, size: 60, color: AppTheme.primaryColor),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Name Field
                FormBuilderTextField(
                  name: 'name',
                  decoration: InputDecoration(
                    labelText: 'الاسم',
                    enabled: _isEditing,
                  ),
                  validator: FormBuilderValidators.required(errorText: 'هذا الحقل مطلوب'),
                ),
                const SizedBox(height: 16),
                
                // Email Field (Read only)
                FormBuilderTextField(
                  name: 'email',
                  decoration: InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    enabled: false,
                    filled: true,
                    fillColor: AppTheme.greyColor,
                  ),
                  initialValue: authProvider.user?.email ?? '',
                  readOnly: true,
                ),
                const SizedBox(height: 16),
                
                // Phone Field
                FormBuilderTextField(
                  name: 'phone',
                  decoration: InputDecoration(
                    labelText: 'رقم الهاتف',
                    enabled: _isEditing,
                    hintText: '05XXXXXXXX',
                  ),
                  keyboardType: TextInputType.phone,
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
                    enabled: _isEditing,
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
                    enabled: _isEditing,
                  ),
                  inputType: InputType.date,
                  format: DateFormat('dd/MM/yyyy'),
                  firstDate: DateTime(1940),
                  lastDate: DateTime.now(),
                  enabled: _isEditing,
                  validator: FormBuilderValidators.required(errorText: 'هذا الحقل مطلوب'),
                ),
                const SizedBox(height: 32),
                
                if (_isLoading)
                  Center(child: SpinKitCircle(color: AppTheme.primaryColor, size: 40)),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Future<void> _saveProfile() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() => _isLoading = true);
      
      final values = _formKey.currentState!.value;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      try {
        await authProvider.updateProfile(
          name: values['name'],
          phone: values['phone'],
          height: double.parse(values['height']),
          dateOfBirth: values['dateOfBirth'],
        );
        
        if (mounted) {
          setState(() {
            _isEditing = false;
            _isLoading = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تم تحديث الملف الشخصي بنجاح')),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل تحديث الملف الشخصي. الرجاء المحاولة مرة أخرى.')),
          );
        }
      }
    }
  }
}