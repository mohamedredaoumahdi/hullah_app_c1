// lib/features/home/screens/home_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
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
    final userName = authProvider.userData?['name'] ?? 'العميلة';
    
    return RTLScaffold(
      title: 'الصفحة الرئيسية',
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              AppTheme.topGradientColor.withOpacity(0.3),
            ],
          ),
        ),
        child: _isLoading 
          ? _buildLoadingState()
          : _errorMessage != null 
            ? _buildErrorState()
            : _buildHomeContent(context, userName, userSummaries),
      ),
    );
  }
  
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryColor),
          const SizedBox(height: 16),
          Text('جاري تحميل البيانات...'),
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
            'حدث خطأ أثناء تحميل البيانات',
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
  
  Widget _buildHomeContent(BuildContext context, String userName, List<Map<String, dynamic>> userSummaries) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome header with background image
          _buildWelcomeHeader(context, userName),
          
          // Quick actions
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الخدمات',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 16),
                _buildQuickActions(context),
                
                const SizedBox(height: 30),
                
                // Recent summaries section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'التجارب السابقة',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    if (userSummaries.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          // Navigate to a separate page showing all experiments
                          // This would be implemented based on your navigation structure
                        },
                        child: Text('عرض الكل'),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                userSummaries.isEmpty
                  ? _buildEmptyPreviousTrials(context)
                  : _buildPreviousTrials(context, userSummaries),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildWelcomeHeader(BuildContext context, String userName) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primaryColor,
            AppTheme.bottomGradientColor,
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
        // image: DecorationImage(
        //   image: AssetImage('assets/images/abaya_pattern.png'),
        //   fit: BoxFit.cover,
        //   opacity: 0.1,
        // ),
      ),
      child: Stack(
        children: [
          // Positioned image to the left (RTL layout, so visually on the right)
          // Positioned(
          //   left: -30,
          //   bottom: -20,
          //   child: Image.asset(
          //     'assets/images/abaya_silhouette.jpeg',
          //     height: 200,
          //     opacity: AlwaysStoppedAnimation(0.3),
          //   ),
          // ),
          // Text content
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'مرحباً بك',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                Text(
                  userName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'ماذا تحتاجين اليوم؟',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionCard(
          context,
          icon: Icons.add_photo_alternate,
          title: 'تجربة جديدة',
          onTap: () => context.go('/measurements/instructions'),
        ),
        _buildActionCard(
          context,
          icon: Icons.history,
          title: 'تجارب سابقة',
          onTap: () {
            // Navigate to experiments page
            // Or scroll to experiments section
          },
        ),
        _buildActionCard(
          context,
          icon: Icons.person,
          title: 'الملف الشخصي',
          onTap: () => context.go('/profile'),
        ),
      ],
    );
  }
  
  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.27,
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmptyPreviousTrials(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'لا توجد تجارب سابقة',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'ابدأ تجربتك الأولى وستظهر هنا',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => context.go('/measurements/instructions'),
            icon: Icon(Icons.add),
            label: Text('تجربة جديدة'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPreviousTrials(BuildContext context, List<Map<String, dynamic>> summaries) {
    // Show at most 3 most recent summaries
    final recentSummaries = summaries.take(3).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...recentSummaries.map((summary) => _buildSummaryCard(context, summary)).toList(),
        
        SizedBox(height: 16),
        
        // "View All" button
        if (summaries.length > 3)
          OutlinedButton(
            onPressed: () {
              // Navigate to a view that shows all summaries
            },
            child: Text('عرض جميع التجارب (${summaries.length})'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          
        // Start New button  
        SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () => context.go('/measurements/instructions'),
          icon: Icon(Icons.add),
          label: Text('تجربة جديدة'),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }
  
  Widget _buildSummaryCard(BuildContext context, Map<String, dynamic> summary) {
    final summaryProvider = Provider.of<SummaryProvider>(context, listen: false);
    final dynamic timestampValue = summary['timestamp'];
    DateTime timestamp;
    final profile = summary['profile'] ?? {};
    final selectedAbayas = summary['selectedAbayas'] ?? [];

    if (timestampValue is Timestamp) {
      timestamp = timestampValue.toDate();
    } else if (timestampValue is String) {
      try {
        timestamp = DateTime.parse(timestampValue);
      } catch (e) {
        timestamp = DateTime.now(); // Fallback for invalid date strings
      }
    } else {
      timestamp = DateTime.now(); // Fallback for null/unexpected types
    }
    
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () {
          summaryProvider.setActiveSummary(summary);
          context.go('/summary');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryColor,
                    child: Icon(
                      Icons.history,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تجربة ${_formatDate(timestamp)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${selectedAbayas.length} عباءات مختارة',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 20,
                    color: Colors.grey,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _formatDate(DateTime timestamp) {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }
}