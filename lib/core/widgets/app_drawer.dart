import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../../features/auth/providers/auth_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Drawer(
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
            _buildDrawerItem(
              context: context,
              icon: Icons.home,
              title: 'الصفحة الرئيسية',
              onTap: () {
                Navigator.pop(context);
                context.go('/home');
              },
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.person,
              title: 'صفحتي',
              onTap: () {
                Navigator.pop(context);
                context.go('/profile');
              },
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.straighten,
              title: 'القياسات',
              onTap: () {
                Navigator.pop(context);
                context.go('/measurements/input');
              },
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.checkroom,
              title: 'اختيار العبايات',
              onTap: () {
                Navigator.pop(context);
                context.go('/abayas/selection');
              },
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.summarize,
              title: 'ملخصي',
              onTap: () {
                Navigator.pop(context);
                context.go('/summary');
              },
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.support_agent,
              title: 'الدعم',
              onTap: () {
                Navigator.pop(context);
                context.go('/support');
              },
            ),
            Divider(),
            _buildDrawerItem(
              context: context,
              icon: Icons.logout,
              title: 'تسجيل الخروج',
              textColor: Colors.red,
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
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: textColor ?? AppTheme.blackColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? AppTheme.blackColor,
        ),
      ),
      onTap: onTap,
    );
  }
}