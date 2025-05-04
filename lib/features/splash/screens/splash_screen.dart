// lib/features/splash/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart' as app_auth;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Set up animations
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(0.0, 0.5, curve: Curves.easeIn),
    ));
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));
    
    // Start animation
    _controller.forward();
    
    // Wait and then navigate to the next screen
    _navigateToNext();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _navigateToNext() async {
    try {
      // Wait for animation and give time for Firebase to settle
      await Future.delayed(const Duration(seconds: 5));
      
      if (!mounted) return;

      // Check if the user is authenticated
      final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
      
      // Navigate to the Start screen regardless of authentication status
      context.go('/start');
    } catch (e) {
      print('Error in splash navigation: $e');
      // If there's an error, still try to navigate to start
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Center(
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Image.asset(
                        'assets/images/app_logo_2.png',
                        width: 240,
                        height: 240,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'حلة',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 3.0,
                            color: Colors.black.withOpacity(0.3),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'لكل انثى حلة تليق بها',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 2.0,
                            color: Colors.black.withOpacity(0.3),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    SpinKitCircle(
                      color: Colors.white,
                      size: 40,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}