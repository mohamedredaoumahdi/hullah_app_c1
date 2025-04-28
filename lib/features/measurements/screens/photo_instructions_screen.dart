// lib/features/measurements/screens/photo_instructions_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/rtl_scaffold.dart';

class PhotoInstructionsScreen extends StatelessWidget {
  const PhotoInstructionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RTLScaffold(
      title: 'تعليمات أخذ الصورة',
      showBackButton: true,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context),
                const SizedBox(height: 24),
                _buildInstructionCard(
                  context, 
                  '1. الوضعية المناسبة',
                  'قفي منتصبة وبشكل طبيعي مع إبقاء ذراعيك قليلاً بعيداً عن جسمك.',
                  Icons.accessibility_new,
                ),
                _buildInstructionCard(
                  context, 
                  '2. الملابس المناسبة',
                  'ارتدي ملابس ضيقة أو متوسطة لتظهر شكل الجسم بشكل أفضل.',
                  Icons.checkroom,
                ),
                _buildInstructionCard(
                  context, 
                  '3. الصورة الكاملة',
                  'تأكدي من ظهور الجسم كاملاً من الرأس إلى القدمين في الصورة.',
                  Icons.photo_size_select_actual,
                ),
                _buildInstructionCard(
                  context, 
                  '4. الإضاءة الجيدة',
                  'اختاري مكاناً جيد الإضاءة بحيث تكون الصورة واضحة ودون ظلال.',
                  Icons.wb_sunny,
                ),
                _buildInstructionCard(
                  context, 
                  '5. الخلفية البسيطة',
                  'استخدمي خلفية سادة (مثل جدار أبيض) لتحسين دقة التحليل.',
                  Icons.wallpaper,
                ),
                const SizedBox(height: 30),
                _buildPrivacyNote(context),
                const SizedBox(height: 40),
                _buildActionButtons(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.photo_camera,
          size: 70,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(height: 16),
        Text(
          'تعليمات التقاط صورة دقيقة',
          style: Theme.of(context).textTheme.displaySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'لضمان دقة تحليل قياسات الجسم، يرجى اتباع التعليمات التالية عند التقاط الصورة:',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInstructionCard(
    BuildContext context, 
    String title, 
    String description, 
    IconData icon
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyNote(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.security, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                'ملاحظة خصوصية:',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'يتم استخدام الصور فقط لتحليل القياسات ولا يتم تخزينها. خصوصيتك مهمة لنا.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () => context.go('/measurements/upload'),
          icon: Icon(Icons.photo_camera),
          label: Text('أخذ صورة الآن'),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => context.go('/measurements/input'),
          icon: Icon(Icons.edit),
          label: Text('إدخال القياسات يدوياً'),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }
}