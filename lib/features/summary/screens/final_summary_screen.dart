import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/rtl_scaffold.dart';
import '../providers/summary_provider.dart';

class FinalSummaryScreen extends StatefulWidget {
  const FinalSummaryScreen({super.key});

  @override
  State<FinalSummaryScreen> createState() => _FinalSummaryScreenState();
}

class _FinalSummaryScreenState extends State<FinalSummaryScreen> {
  bool _hasChanges = false;

  Future<bool> _confirmSubmission() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد الطلب النهائي'),
        content: Text('هل أنت متأكدة من إرسال الطلب؟ لا يمكنك التراجع بعد هذه الخطوة.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('تأكيد', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _submitFinalOrder() async {
    // Confirm submission first
    final confirmed = await _confirmSubmission();
    
    if (confirmed) {
      setState(() {
        _hasChanges = false;
      });
      
      // Navigate to thank you screen
      context.go('/thank-you');
    }
  }

  @override
  Widget build(BuildContext context) {
    final summaryProvider = Provider.of<SummaryProvider>(context);
    
    return RTLScaffold(
      title: 'الملخص النهائي',
      showBackButton: true,
      confirmOnBack: _hasChanges,
      fallbackRoute: '/summary',
      confirmationMessage: 'هل أنت متأكدة من الخروج؟ سيتم فقدان التغييرات غير المحفوظة.',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'مراجعة الطلب النهائي',
              style: Theme.of(context).textTheme.displaySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Customer Information Card
            _buildCustomerInfoCard(context, summaryProvider),
            const SizedBox(height: 16),
            
            // Measurements Card (Read-only)
            _buildMeasurementsCard(context, summaryProvider),
            const SizedBox(height: 16),
            
            // Selected Abayas Summary
            Text(
              'العبايات المختارة (${summaryProvider.selectedAbayas.length})',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 12),
            ...summaryProvider.selectedAbayas.map((abaya) => 
              _buildAbayaSummaryCard(context, abaya)
            ),
            const SizedBox(height: 24),
            
            // Final Submission Button
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _hasChanges = true;
                });
                _submitFinalOrder();
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text('اللمسات الأخيرة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfoCard(BuildContext context, SummaryProvider provider) {
    final profile = provider.summary?['profile'] ?? {};
    
    return Card(
      color: AppTheme.greyColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'بيانات العميلة',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('الاسم', profile['name']?.toString() ?? ''),
            _buildInfoRow('رقم الهاتف', profile['phone']?.toString() ?? ''),
            _buildInfoRow('الطول', '${profile['height']?.toString() ?? ''} سم'),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementsCard(BuildContext context, SummaryProvider provider) {
    final measurements = provider.summary?['measurements'] ?? {};
    
    return Card(
      color: AppTheme.greyColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'القياسات',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
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

  Widget _buildAbayaSummaryCard(BuildContext context, abaya) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: abaya.image1Url,
              width: 100,
              height: 120,
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
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    abaya.model,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('القماش: ${abaya.fabric}'),
                  Text('اللون: ${abaya.color}'),
                  const SizedBox(height: 8),
                  Text(
                    abaya.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
            style: TextStyle(color: Colors.grey[700]),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}