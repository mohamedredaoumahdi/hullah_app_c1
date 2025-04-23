import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hullah_app/features/abayas/models/abaya_model.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/rtl_scaffold.dart';
import '../providers/summary_provider.dart';

class MySummaryScreen extends StatefulWidget {
  const MySummaryScreen({super.key});

  @override
  State<MySummaryScreen> createState() => _MySummaryScreenState();
}

class _MySummaryScreenState extends State<MySummaryScreen> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormBuilderState>();
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    final summaryProvider = Provider.of<SummaryProvider>(context, listen: false);
    await summaryProvider.loadSummary();
  }

  @override
  Widget build(BuildContext context) {
    final summaryProvider = Provider.of<SummaryProvider>(context);
    
    if (summaryProvider.isLoading) {
      return RTLScaffold(
        title: 'ملخصي',
        showBackButton: true,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return RTLScaffold(
      title: 'ملخصي',
      showBackButton: true,
      confirmOnBack: _isEditing || _hasChanges, // Show confirmation if editing
      confirmationMessage: 'هل أنت متأكد من الخروج؟ سيتم فقدان التغييرات غير المحفوظة.',
      actions: [
        if (!_isEditing)
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () => setState(() => _isEditing = true),
          ),
        if (_isEditing)
          IconButton(
            icon: Icon(Icons.check),
            onPressed: _saveMeasurements,
          ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Information
            _buildSectionHeader('معلومات العميلة'),
            _buildUserInfoCard(summaryProvider),
            const SizedBox(height: 24),
            
            // Measurements
            _buildSectionHeader('القياسات'),
            _buildMeasurementsCard(summaryProvider),
            const SizedBox(height: 24),
            
            // Selected Abayas
            _buildSectionHeader('العبايات المختارة'),
            _buildSelectedAbayasSection(summaryProvider),
            const SizedBox(height: 24),
            
            // Action Buttons
            ElevatedButton.icon(
              onPressed: () => context.go('/summary/final'),
              icon: Icon(Icons.arrow_forward),
              label: Text('التالي'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _generatePDF,
              icon: Icon(Icons.picture_as_pdf),
              label: Text('تصدير PDF'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.displaySmall,
      ),
    );
  }

  Widget _buildUserInfoCard(SummaryProvider provider) {
    final profile = provider.summary?['profile'] ?? {};
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('الاسم', profile['name']?.toString() ?? ''),
            _buildInfoRow('رقم الهاتف', profile['phone']?.toString() ?? ''),
            _buildInfoRow('الطول', '${profile['height']?.toString() ?? ''} سم'),
            _buildInfoRow(
              'تاريخ الميلاد',
              profile['dateOfBirth'] != null
                  ? '${profile['dateOfBirth'].toDate().day}/${profile['dateOfBirth'].toDate().month}/${profile['dateOfBirth'].toDate().year}'
                  : '',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementsCard(SummaryProvider provider) {
    final measurements = provider.summary?['measurements'] ?? {};
    
    if (_isEditing) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FormBuilder(
            key: _formKey,
            initialValue: {
              'chest': measurements['chest']?.toString() ?? '',
              'waist': measurements['waist']?.toString() ?? '',
              'hips': measurements['hips']?.toString() ?? '',
              'shoulder': measurements['shoulder']?.toString() ?? '',
              'armLength': measurements['armLength']?.toString() ?? '',
            },
            onChanged: () {
              // Set flag when changes are made
              if (!_hasChanges) {
                setState(() {
                  _hasChanges = true;
                });
              }
            },
            child: Column(
              children: [
                _buildEditableField('chest', 'محيط الصدر'),
                _buildEditableField('waist', 'محيط الخصر'),
                _buildEditableField('hips', 'محيط الأرداف'),
                _buildEditableField('shoulder', 'عرض الكتفين'),
                _buildEditableField('armLength', 'طول الذراع'),
              ],
            ),
          ),
        ),
      );
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('محيط الصدر', '${measurements['chest']?.toString() ?? ''} سم'),
            _buildInfoRow('محيط الخصر', '${measurements['waist']?.toString() ?? ''} سم'),
            _buildInfoRow('محيط الأرداف', '${measurements['hips']?.toString() ?? ''} سم'),
            _buildInfoRow('عرض الكتفين', '${measurements['shoulder']?.toString() ?? ''} سم'),
            _buildInfoRow('طول الذراع', '${measurements['armLength']?.toString() ?? ''} سم'),
            _buildInfoRow('شكل الجسم', measurements['bodyShape']?.toString() ?? ''),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField(String name, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FormBuilderTextField(
        name: name,
        decoration: InputDecoration(
          labelText: label,
          suffix: Text('سم'),
        ),
        keyboardType: TextInputType.number,
        validator: FormBuilderValidators.compose([
          FormBuilderValidators.required(errorText: 'هذا الحقل مطلوب'),
          FormBuilderValidators.numeric(errorText: 'يجب أن يكون رقماً'),
          FormBuilderValidators.min(20, errorText: 'القيمة صغيرة جداً'),
          FormBuilderValidators.max(250, errorText: 'القيمة كبيرة جداً'),
        ]),
      ),
    );
  }

  Widget _buildSelectedAbayasSection(SummaryProvider provider) {
    if (provider.selectedAbayas.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.checkroom, size: 48, color: AppTheme.greyColor),
                const SizedBox(height: 8),
                Text('لم يتم اختيار أي عبايات بعد'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => context.go('/abayas/selection'),
                  icon: Icon(Icons.add),
                  label: Text('اختيار عبايات'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return Column(
      children: provider.selectedAbayas.map((abaya) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: abaya.image1Url,
                    width: 80,
                    height: 100,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppTheme.greyColor,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppTheme.greyColor,
                      child: Icon(Icons.error),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        abaya.model,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('القماش: ${abaya.fabric}'),
                      Text('اللون: ${abaya.color}'),
                      Text(
                        abaya.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _confirmDeleteAbaya(abaya.id, provider),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveMeasurements() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final values = _formKey.currentState!.value;
      final summaryProvider = Provider.of<SummaryProvider>(context, listen: false);
      
      try {
        final updatedMeasurements = {
          'chest': double.parse(values['chest']),
          'waist': double.parse(values['waist']),
          'hips': double.parse(values['hips']),
          'shoulder': double.parse(values['shoulder']),
          'armLength': double.parse(values['armLength']),
        };
        
        await summaryProvider.updateMeasurements(updatedMeasurements);
        
        if (mounted) {
          setState(() {
            _isEditing = false;
            _hasChanges = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تم تحديث القياسات بنجاح')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل في تحديث القياسات')),
          );
        }
      }
    }
  }

  Future<void> _confirmDeleteAbaya(String abayaId, SummaryProvider provider) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('تأكيد الحذف'),
          content: Text('هل أنت متأكدة من حذف هذه العباية؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('حذف', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
    
    if (result == true && mounted) {
      final updatedAbayas = List<AbayaModel>.from(provider.selectedAbayas)
        ..removeWhere((abaya) => abaya.id == abayaId);
      await provider.updateSummary(selectedAbayas: updatedAbayas);
    }
  }

  Future<void> _generatePDF() async {
    final summaryProvider = Provider.of<SummaryProvider>(context, listen: false);
    
    try {
      final file = await summaryProvider.generatePDF();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم إنشاء ملف PDF بنجاح')),
        );
        // Open the PDF file or share it
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في إنشاء ملف PDF')),
        );
      }
    }
  }
}