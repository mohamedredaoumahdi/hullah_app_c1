import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hullah_app/features/abayas/providers/abayas_provider.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/rtl_scaffold.dart';
import '../providers/measurements_provider.dart';

class BodyAnalysisScreen extends StatelessWidget {
  const BodyAnalysisScreen({super.key});

  // Function to show confirmation dialog
  Future<bool> _confirmRetakeMeasurements(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد العودة'),
        content: Text('هل أنت متأكد من العودة لإعادة أخذ القياسات؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('نعم', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final measurementsProvider = Provider.of<MeasurementsProvider>(context);
    final measurements = measurementsProvider.measurements;
    final bodyShape = measurementsProvider.bodyShape;
    
    if (measurements == null || bodyShape == null) {
      return RTLScaffold(
        title: 'تحليل الجسم',
        showBackButton: true,
        body: Center(
          child: Text('لا توجد قياسات متوفرة'),
        ),
      );
    }
    
    return RTLScaffold(
      title: 'تحليل الجسم',
      showBackButton: true,
      confirmOnBack: true,
      fallbackRoute: '/measurements/input',
      confirmationMessage: 'هل أنت متأكد من العودة لإعادة أخذ القياسات؟',
      onBackPressed: () {
        // Optional: Add any cleanup or state reset logic here
      },
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Body Shape Result Card
            Card(
              color: AppTheme.primaryColor,
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'شكل جسمك هو',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      bodyShape,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Icon(
                      _getBodyShapeIcon(bodyShape),
                      size: 60,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Measurements Summary
            Text(
              'ملخص القياسات',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 16),
            _buildMeasurementRow(
              context,
              'محيط الصدر',
              '${measurements['chest']?.toInt() ?? 0} سم',
            ),
            _buildMeasurementRow(
              context,
              'محيط الخصر',
              '${measurements['waist']?.toInt() ?? 0} سم',
            ),
            _buildMeasurementRow(
              context,
              'محيط الأرداف',
              '${measurements['hips']?.toInt() ?? 0} سم',
            ),
            _buildMeasurementRow(
              context,
              'عرض الكتفين',
              '${measurements['shoulder']?.toInt() ?? 0} سم',
            ),
            _buildMeasurementRow(
              context,
              'طول الذراع',
              '${measurements['armLength']?.toInt() ?? 0} سم',
            ),
            _buildMeasurementRow(
              context,
              'الطول',
              '${measurements['height']?.toInt() ?? 0} سم',
            ),
            const SizedBox(height: 32),
            
            // Recommendations
            Text(
              'توصيات العبايات',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _getRecommendations(bodyShape)
                      .map((recommendation) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: AppTheme.primaryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    recommendation,
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            ElevatedButton.icon(
  onPressed: () {
    final abayasProvider = Provider.of<AbayasProvider>(context, listen: false);
    final measurementsProvider = Provider.of<MeasurementsProvider>(context, listen: false);
    final bodyShape = measurementsProvider.bodyShape;
    
    // Explicitly force Firestore-only loading
    abayasProvider.loadRecommendedAbayas(
      bodyShape: bodyShape, 
      useFirestoreOnly: true  // Strictly use Firestore
    ).then((_) {
      // Navigate to abaya selection screen
      context.go('/abayas/selection');
    }).catchError((error) {
      // Handle potential errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل في تحميل العبايات: $error'),
          action: SnackBarAction(
            label: 'حسناً',
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    });
  },
  icon: Icon(Icons.checkroom),
  label: Text('متابعة لاختيار العبايات'),
  style: ElevatedButton.styleFrom(
    padding: EdgeInsets.symmetric(vertical: 16),
  ),
),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMeasurementRow(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.greyColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  IconData _getBodyShapeIcon(String bodyShape) {
    switch (bodyShape) {
      case 'ساعة رملية':
        return Icons.hourglass_full;
      case 'كمثرى':
        return Icons.filter_vintage;
      case 'مثلث مقلوب':
        return Icons.change_history;
      case 'مستطيل':
        return Icons.crop_square;
      case 'تفاحة':
        return Icons.circle;
      default:
        return Icons.person;
    }
  }
  
  List<String> _getRecommendations(String bodyShape) {
    switch (bodyShape) {
      case 'ساعة رملية':
        return [
          'عبايات بخصر محدد لإبراز شكل الجسم المتناسق',
          'عبايات بقصات كلاسيكية تعزز التوازن الطبيعي للجسم',
          'تفاصيل على الخصر مثل الأحزمة أو التطريز',
        ];
      case 'كمثرى':
        return [
          'عبايات بتفاصيل على الجزء العلوي لخلق التوازن',
          'قصات A-line التي تخفي منطقة الأرداف',
          'أكمام واسعة أو منفوخة لتوسيع منطقة الأكتاف',
        ];
      case 'مثلث مقلوب':
        return [
          'عبايات بقصات واسعة من الأسفل لتوازن الجسم',
          'تفاصيل وتطريز على الجزء السفلي',
          'أكمام بسيطة لتقليل عرض الأكتاف',
        ];
      case 'مستطيل':
        return [
          'عبايات بخصر محدد لخلق منحنيات',
          'قصات مموجة وطبقات لإضافة بعد للجسم',
          'تفاصيل على الصدر والأرداف لإضافة حجم',
        ];
      case 'تفاحة':
        return [
          'عبايات بقصات مستقيمة تخفي منطقة البطن',
          'قصات V-neck لإطالة مظهر الجسم',
          'تجنب العبايات الضيقة عند الخصر',
        ];
      default:
        return ['عبايات كلاسيكية متنوعة تناسب معظم أشكال الجسم'];
    }
  }
}