// lib/core/routes/app_router.dart
import 'dart:io';

import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hullah_app/features/summary/screens/pdf_viewer_screen.dart';
import '../utils/navigation_utils.dart';

import '../../features/splash/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/measurements/screens/measurements_input_screen.dart';
import '../../features/measurements/screens/image_upload_screen.dart';
import '../../features/measurements/screens/photo_instructions_screen.dart';
import '../../features/measurements/screens/body_analysis_screen.dart';
import '../../features/abayas/screens/abaya_selection_screen.dart';
import '../../features/abayas/screens/abaya_details_screen.dart';
import '../../features/summary/screens/my_summary_screen.dart';
import '../../features/summary/screens/final_summary_screen.dart';
import '../../features/support/screens/support_screen.dart';
import '../../features/thank_you/screens/thank_you_screen.dart';
import '../../features/start/screens/start_screen.dart';
import '../../features/auth/providers/auth_provider.dart' as app_auth;

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/splash',
    redirect: (BuildContext context, GoRouterState state) {
      // Get the auth provider to check authentication status
      final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
      final isAuthenticated = authProvider.isAuthenticated;
      
      // Don't redirect for splash screen
      if (state.matchedLocation == '/splash') {
        return null;
      }
      
      // Define auth routes (routes that don't require authentication)
      final isAuthRoute = state.matchedLocation == '/login' || 
                          state.matchedLocation == '/register' ||
                          state.matchedLocation == '/start';
      
      // If user is not authenticated and trying to access a protected route,
      // redirect to login
      if (!isAuthenticated && !isAuthRoute) {
        return '/login';
      }
      
      // If user is authenticated and trying to access auth routes,
      // redirect to home
      if (isAuthenticated && isAuthRoute) {
        return '/home';
      }
      
      // No redirect needed
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/start',
        builder: (context, state) => const StartScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/measurements/instructions',
        builder: (context, state) => const PhotoInstructionsScreen(),
      ),
      GoRoute(
        path: '/measurements/input',
        builder: (context, state) => const MeasurementsInputScreen(),
      ),
      GoRoute(
        path: '/measurements/upload',
        builder: (context, state) => const ImageUploadScreen(),
      ),
      GoRoute(
        path: '/measurements/analysis',
        builder: (context, state) => const BodyAnalysisScreen(),
      ),
      GoRoute(
        path: '/abayas/selection',
        builder: (context, state) => const AbayaSelectionScreen(),
      ),
      GoRoute(
        path: '/abayas/details/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AbayaDetailsScreen(abayaId: id);
        },
      ),
      GoRoute(
        path: '/summary',
        builder: (context, state) => const MySummaryScreen(),
      ),
      GoRoute(
        path: '/summary/final',
        builder: (context, state) => const FinalSummaryScreen(),
      ),
      GoRoute(
        path: '/support',
        builder: (context, state) => const SupportScreen(),
      ),
      GoRoute(
        path: '/thank-you',
        builder: (context, state) => const ThankYouScreen(),
      ),
      GoRoute(
        path: '/pdf-viewer',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          final pdfFile = args['pdfFile'] as File;
          final title = args['title'] as String? ?? 'عرض الملف';
          return PdfViewerScreen(pdfFile: pdfFile, title: title);
        },
      ),
    ],
  );
}

/// Extension methods for enhanced GoRouter functionality
extension GoRouterExtensions on GoRouter {
  /// A wrapper to enhance GoRouter's error handling for navigation
  ///
  /// This wrapper handles common edge cases in navigation like rapidly
  /// pressing the back button, which can lead to inconsistent behavior
  void safeGo(BuildContext context, String location) {
    try {
      go(location);
    } catch (e) {
      print('Error navigating to $location: $e');
      // Try a fallback approach if the standard go() fails
      try {
        // First try to push instead of go
        push(location);
      } catch (e2) {
        print('Fallback push failed too: $e2');
        // Last resort - use system back navigation
        if (context.mounted) {
          context.safeNavigateBack();
        }
      }
    }
  }
}