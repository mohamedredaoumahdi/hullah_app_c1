import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('الصفحة الرئيسية'),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.white,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'مرحباً',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      authProvider.userData?['name'] ?? 'المستخدم',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: Icon(Icons.home, color: AppTheme.blackColor),
                title: Text('الصفحة الرئيسية'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/home');
                },
              ),
              ListTile(
                leading: Icon(Icons.person, color: AppTheme.blackColor),
                title: Text('صفحتي'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/profile');
                },
              ),
              ListTile(
                leading: Icon(Icons.straighten, color: AppTheme.blackColor),
                title: Text('القياسات'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/measurements/input');
                },
              ),
              ListTile(
                leading: Icon(Icons.checkroom, color: AppTheme.blackColor),
                title: Text('اختيار العبايات'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/abayas/selection');
                },
              ),
              ListTile(
                leading: Icon(Icons.summarize, color: AppTheme.blackColor),
                title: Text('ملخصي'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/summary');
                },
              ),
              ListTile(
                leading: Icon(Icons.support_agent, color: AppTheme.blackColor),
                title: Text('الدعم'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/support');
                },
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.logout, color: Colors.red),
                title: Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  await authProvider.logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
              ),
            ],
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'مرحباً بك في تطبيق تفصيل العباية',
              style: Theme.of(context).textTheme.displaySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.go('/measurements/input'),
              icon: Icon(Icons.straighten),
              label: Text('البدء بإدخال القياسات'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => context.go('/measurements/upload'),
              icon: Icon(Icons.camera_alt),
              label: Text('رفع صورة للقياسات'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                side: BorderSide(color: AppTheme.primaryColor),
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}