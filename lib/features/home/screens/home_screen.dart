// lib/features/home/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/rtl_scaffold.dart';
import '../../summary/providers/summary_provider.dart';
import '../../auth/providers/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserSummaries();
    });
  }

  Future<void> _loadUserSummaries() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final summaryProvider = Provider.of<SummaryProvider>(context, listen: false);
      await summaryProvider.loadAllUserSummaries();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final summaryProvider = Provider.of<SummaryProvider>(context);
    final userSummaries = summaryProvider.allUserSummaries;
    
    return RTLScaffold(
      title: 'الصفحة الرئيسية',
      body: _isLoading 
        ? _buildLoadingState()
        : _errorMessage != null 
          ? _buildErrorState()
          : userSummaries.isEmpty
            ? _buildEmptyState(context)
            : _buildSummariesList(context, userSummaries),
    );
  }
  
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryColor),
          const SizedBox(height: 16),
          Text('جاري تحميل الملخصات...'),
        ],
      ),
    );
  }
  
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'حدث خطأ أثناء تحميل الملخصات',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(_errorMessage ?? 'خطأ غير معروف'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadUserSummaries,
            icon: Icon(Icons.refresh),
            label: Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'مرحباً بك في تطبيق تفصيل العباية',
            style: Theme.of(context).textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Image.asset(
            'assets/images/app_logo_2.png',
            width: 150,
            height: 150,
          ),
          const SizedBox(height: 32),
          Text(
            'لم تقم بإنشاء أي ملخصات بعد',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildNewSummaryButton(context),
        ],
      ),
    );
  }
  
  Widget _buildSummariesList(BuildContext context, List<Map<String, dynamic>> summaries) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'الملخصات السابقة',
            style: Theme.of(context).textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: summaries.length + 1, // +1 for the "Add New" button
            itemBuilder: (context, index) {
              if (index == summaries.length) {
                // Last item is the "Add New" button
                return _buildNewSummaryCard(context);
              }
              
              final summary = summaries[index];
              return _buildSummaryCard(context, summary, index);
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildSummaryCard(BuildContext context, Map<String, dynamic> summary, int index) {
    final summaryProvider = Provider.of<SummaryProvider>(context, listen: false);
    final timestamp = summary['timestamp']?.toDate() ?? DateTime.now();
    final profile = summary['profile'] ?? {};
    final selectedAbayas = summary['selectedAbayas'] ?? [];
    
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          summaryProvider.setActiveSummary(summary);
          context.go('/summary');
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ملخص ${index + 1}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'تاريخ الإنشاء: ${_formatDate(timestamp)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.person, size: 16, color: Colors.grey[600]),
                            SizedBox(width: 4),
                            Text(
                              '${profile['name'] ?? 'غير محدد'}',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.checkroom, size: 16, color: Colors.grey[600]),
                            SizedBox(width: 4),
                            Text(
                              'العبايات: ${selectedAbayas.length}',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.more_vert),
                    onPressed: () => _showSummaryOptions(context, summary, index),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildNewSummaryCard(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      color: Colors.grey[100],
      child: InkWell(
        onTap: () => _startNewSummary(context),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                Icons.add_circle,
                size: 48,
                color: AppTheme.primaryColor,
              ),
              SizedBox(height: 16),
              Text(
                'إنشاء ملخص جديد',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildNewSummaryButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _startNewSummary(context),
      icon: Icon(Icons.add),
      label: Text('إنشاء ملخص جديد'),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      ),
    );
  }
  
  void _startNewSummary(BuildContext context) {
    // Reset the current summary to start a fresh one
    final summaryProvider = Provider.of<SummaryProvider>(context, listen: false);
    summaryProvider.clearSummary();
    
    // Start the measurements flow
    context.go('/measurements/input');
  }
  
  void _showSummaryOptions(BuildContext context, Map<String, dynamic> summary, int index) {
    final summaryProvider = Provider.of<SummaryProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.remove_red_eye),
            title: Text('عرض الملخص'),
            onTap: () {
              Navigator.pop(context);
              summaryProvider.setActiveSummary(summary);
              context.go('/summary');
            },
          ),
          ListTile(
            leading: Icon(Icons.edit),
            title: Text('تعديل الملخص'),
            onTap: () {
              Navigator.pop(context);
              summaryProvider.setActiveSummary(summary);
              context.go('/measurements/input');
            },
          ),
          ListTile(
            leading: Icon(Icons.content_copy),
            title: Text('نسخ كملخص جديد'),
            onTap: () {
              Navigator.pop(context);
              summaryProvider.duplicateSummary(summary);
              context.go('/measurements/input');
            },
          ),
          ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('حذف الملخص', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _confirmDeleteSummary(context, summary);
            },
          ),
        ],
      ),
    );
  }
  
  void _confirmDeleteSummary(BuildContext context, Map<String, dynamic> summary) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف هذا الملخص؟ لا يمكن التراجع عن هذه العملية.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final summaryProvider = Provider.of<SummaryProvider>(context, listen: false);
              await summaryProvider.deleteSummary(summary);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تم حذف الملخص بنجاح')),
                );
              }
            },
            child: Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    // Simple date formatter
    return '${date.day}/${date.month}/${date.year}';
  }
}