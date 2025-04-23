import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/rtl_scaffold.dart';
import '../providers/measurements_provider.dart';

class MeasurementsInputScreen extends StatefulWidget {
  const MeasurementsInputScreen({super.key});

  @override
  State<MeasurementsInputScreen> createState() => _MeasurementsInputScreenState();
}

class _MeasurementsInputScreenState extends State<MeasurementsInputScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  Widget build(BuildContext context) {
    return RTLScaffold(
      title: 'إدخال القياسات',
      showBackButton: true,
      confirmOnBack: _hasChanges, // Show confirmation if form has changes
      confirmationMessage: 'هل أنت متأكد من الخروج؟ سيتم فقدان القياسات المدخلة.',
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: FormBuilder(
            key: _formKey,
            onChanged: () {
              // Set flag to true when user starts changing form values
              if (!_hasChanges) {
                setState(() {
                  _hasChanges = true;
                });
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'الرجاء إدخال القياسات بالسنتيمتر',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // Chest Measurement
                FormBuilderTextField(
                  name: 'chest',
                  decoration: InputDecoration(
                    labelText: 'محيط الصدر',
                    hintText: 'أدخل قياس الصدر بـ cm',
                  ),
                  keyboardType: TextInputType.number,
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(errorText: 'هذا الحقل مطلوب'),
                    FormBuilderValidators.numeric(errorText: 'يجب أن يكون رقماً'),
                    FormBuilderValidators.min(50, errorText: 'القيمة صغيرة جداً'),
                    FormBuilderValidators.max(200, errorText: 'القيمة كبيرة جداً'),
                  ]),
                ),
                const SizedBox(height: 16),
                
                // Waist Measurement
                FormBuilderTextField(
                  name: 'waist',
                  decoration: InputDecoration(
                    labelText: 'محيط الخصر',
                    hintText: 'أدخل قياس الخصر بـ cm',
                  ),
                  keyboardType: TextInputType.number,
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(errorText: 'هذا الحقل مطلوب'),
                    FormBuilderValidators.numeric(errorText: 'يجب أن يكون رقماً'),
                    FormBuilderValidators.min(40, errorText: 'القيمة صغيرة جداً'),
                    FormBuilderValidators.max(180, errorText: 'القيمة كبيرة جداً'),
                  ]),
                ),
                const SizedBox(height: 16),
                
                // Hips Measurement
                FormBuilderTextField(
                  name: 'hips',
                  decoration: InputDecoration(
                    labelText: 'محيط الأرداف',
                    hintText: 'أدخل قياس الأرداف بـ cm',
                  ),
                  keyboardType: TextInputType.number,
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(errorText: 'هذا الحقل مطلوب'),
                    FormBuilderValidators.numeric(errorText: 'يجب أن يكون رقماً'),
                    FormBuilderValidators.min(60, errorText: 'القيمة صغيرة جداً'),
                    FormBuilderValidators.max(200, errorText: 'القيمة كبيرة جداً'),
                  ]),
                ),
                const SizedBox(height: 16),
                
                // Shoulder Measurement
                FormBuilderTextField(
                  name: 'shoulder',
                  decoration: InputDecoration(
                    labelText: 'عرض الكتفين',
                    hintText: 'أدخل قياس الكتفين بـ cm',
                  ),
                  keyboardType: TextInputType.number,
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(errorText: 'هذا الحقل مطلوب'),
                    FormBuilderValidators.numeric(errorText: 'يجب أن يكون رقماً'),
                    FormBuilderValidators.min(30, errorText: 'القيمة صغيرة جداً'),
                    FormBuilderValidators.max(100, errorText: 'القيمة كبيرة جداً'),
                  ]),
                ),
                const SizedBox(height: 16),
                
                // Arm Length Measurement
                FormBuilderTextField(
                  name: 'armLength',
                  decoration: InputDecoration(
                    labelText: 'طول الذراع',
                    hintText: 'أدخل طول الذراع بـ cm',
                  ),
                  keyboardType: TextInputType.number,
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(errorText: 'هذا الحقل مطلوب'),
                    FormBuilderValidators.numeric(errorText: 'يجب أن يكون رقماً'),
                    FormBuilderValidators.min(30, errorText: 'القيمة صغيرة جداً'),
                    FormBuilderValidators.max(100, errorText: 'القيمة كبيرة جداً'),
                  ]),
                ),
                const SizedBox(height: 16),
                
                // Total Height (Read-only from profile)
                FormBuilderTextField(
                  name: 'height',
                  decoration: InputDecoration(
                    labelText: 'الطول الكلي',
                    hintText: 'سيتم جلبه من الملف الشخصي',
                    enabled: false,
                    filled: true,
                    fillColor: AppTheme.greyColor,
                  ),
                  initialValue: context.read<MeasurementsProvider>().userHeight?.toString() ?? '',
                  readOnly: true,
                ),
                const SizedBox(height: 32),
                
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveMeasurements,
                  child: _isLoading
                      ? SpinKitCircle(color: Colors.white, size: 24)
                      : Text('حفظ القياسات'),
                ),
                const SizedBox(height: 16),
                
                Text(
                  'ملاحظة: سيتم حساب شكل الجسم تلقائياً بناءً على القياسات المدخلة',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Future<void> _saveMeasurements() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() => _isLoading = true);
      
      final values = _formKey.currentState!.value;
      final measurementsProvider = Provider.of<MeasurementsProvider>(context, listen: false);
      
      try {
        await measurementsProvider.saveMeasurements(
          chest: double.parse(values['chest']),
          waist: double.parse(values['waist']),
          hips: double.parse(values['hips']),
          shoulder: double.parse(values['shoulder']),
          armLength: double.parse(values['armLength']),
        );
        
        if (mounted) {
          setState(() => _hasChanges = false); // Reset changes flag after successful save
          // Navigate to body analysis screen
          context.go('/measurements/analysis');
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل حفظ القياسات. الرجاء المحاولة مرة أخرى.')),
          );
        }
      }
    }
  }
}