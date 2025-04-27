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
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final measurementsProvider = Provider.of<MeasurementsProvider>(context);
    
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
                const SizedBox(height: 16),
                
                // Display error message if available
                if (_errorMessage != null || measurementsProvider.errorMessage != null)
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
                          _errorMessage ?? measurementsProvider.errorMessage ?? 'حدث خطأ',
                          style: TextStyle(color: Colors.red.shade800),
                          textAlign: TextAlign.center,
                        ),
                        if ((_errorMessage ?? measurementsProvider.errorMessage ?? '').contains('timeout'))
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
                          onPressed: () {
                            setState(() => _errorMessage = null);
                            measurementsProvider.clearError();
                          },
                          child: Text('حسناً'),
                        ),
                      ],
                    ),
                  ),
                
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
                
                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading || measurementsProvider.isLoading ? null : _saveMeasurements,
                  child: _isLoading || measurementsProvider.isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SpinKitCircle(color: Colors.white, size: 24),
                            SizedBox(width: 16),
                            Text('جاري المعالجة...'),
                          ],
                        )
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
                
                // API information note
                const SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'يتم استخدام خادم API مستضاف خارجياً لتحليل القياسات',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Future<void> _saveMeasurements() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      final values = _formKey.currentState!.value;
      final measurementsProvider = Provider.of<MeasurementsProvider>(context, listen: false);
      
      try {
        // Show loading dialog with more information
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SpinKitCircle(color: AppTheme.primaryColor, size: 50),
                  SizedBox(height: 20),
                  Text(
                    'جاري معالجة القياسات...',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'يرجى الانتظار بينما نقوم بتحليل القياسات باستخدام API. قد يستغرق الأمر وقتًا إذا كان الخادم يبدأ تشغيله.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            );
          },
        );
        
        await measurementsProvider.saveMeasurements(
          chest: double.parse(values['chest']),
          waist: double.parse(values['waist']),
          hips: double.parse(values['hips']),
          shoulder: double.parse(values['shoulder']),
          armLength: double.parse(values['armLength']),
        );
        
        if (mounted) {
          Navigator.pop(context); // Close the loading dialog
          setState(() {
            _hasChanges = false;
            _isLoading = false;
          });
          
          // Navigate to body analysis screen
          context.go('/measurements/analysis');
        }
      } catch (e) {
        if (mounted) {
          // Close the loading dialog if it's open
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          
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
  }
}