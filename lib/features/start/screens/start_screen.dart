// lib/features/start/screens/start_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final authProvider = Provider.of<AuthProvider>(context);
    final userName = authProvider.userData?['name'] ?? 'العميلة';
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.topGradientColor,
              AppTheme.middleGradientColor,
              AppTheme.bottomGradientColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top section with logo and greeting
              Expanded(
                flex: 5,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/app_logo_2.png',
                        width: size.width * 0.5,
                        height: size.width * 0.5,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'حلة',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 2),
                              blurRadius: 4,
                              color: Colors.black.withOpacity(0.2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'لكل انثى حلة تليق بها',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 2,
                              color: Colors.black.withOpacity(0.2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Welcome message with user name if logged in
                      if (authProvider.isAuthenticated && !authProvider.isGuest)
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            'مرحباً بك $userName',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              // Bottom part with image
              // Expanded(
              //   flex: 4,
              //   child: Container(
              //     width: double.infinity,
              //     decoration: BoxDecoration(
              //       image: DecorationImage(
              //         image: AssetImage('assets/images/abaya_silhouette.jpeg'),
              //         fit: BoxFit.contain,
              //         alignment: Alignment.topCenter,
              //       ),
              //     ),
              //   ),
              // ),
              
              // Bottom buttons
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!authProvider.isAuthenticated)
                      ElevatedButton(
                        onPressed: () => context.go('/login'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.primaryColor,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          textStyle: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          elevation: 4,
                          shadowColor: Colors.black.withOpacity(0.3),
                        ),
                        child: Text('تسجيل الدخول'),
                      ),
                    //   Padding(
                    //     padding: const EdgeInsets.only(top: 16.0),
                    //     child: TextButton(
                    //       onPressed: () => context.go('/login'),
                    //       style: TextButton.styleFrom(
                    //         foregroundColor: Colors.white,
                    //       ),
                    //       child: Text(
                    //         'تسجيل الدخول',
                    //         style: TextStyle(
                    //           decoration: TextDecoration.underline,
                    //         ),
                    //       ),
                    //     ),
                    //   ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}