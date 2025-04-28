// lib/core/utils/back_navigation_manager.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// A utility class to handle back navigation throughout the app
class BackNavigationManager {
  /// Show a confirmation dialog if needed before navigating back
  static Future<bool> confirmBackNavigation(
    BuildContext context, {
    bool needsConfirmation = false,
    String title = 'تأكيد الخروج',
    String message = 'هل أنت متأكد من الخروج؟ سيتم فقدان البيانات غير المحفوظة.',
  }) async {
    // If confirmation not needed, return true immediately
    if (!needsConfirmation) return true;
    
    // Show confirmation dialog
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('خروج', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }
  
  /// Navigate back with improved reliability
  /// 
  /// This method tries multiple approaches to ensure reliable back navigation
  static Future<void> navigateBack(
    BuildContext context, {
    String? fallbackRoute,
    VoidCallback? onBeforeNavigate,
  }) async {
    // Execute optional callback
    if (onBeforeNavigate != null) {
      onBeforeNavigate();
    }
    
    // Try to pop current route
    bool popped = false;
    
    try {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
        popped = true;
      } 
    } catch (e) {
      print('Error popping route: $e');
    }
    
    // If popping fails and fallback provided, use it
    if (!popped && fallbackRoute != null && context.mounted) {
      try {
        context.go(fallbackRoute);
      } catch (e) {
        print('Error navigating to fallback: $e');
        // Last resort - try popping system navigation
        try {
          await SystemNavigator.pop(animated: true);
        } catch (e2) {
          print('Error with SystemNavigator.pop: $e2');
        }
      }
    }
  }
  
  /// Handle back button including confirmation if needed
  static Future<void> handleBackButton(
    BuildContext context, {
    bool needsConfirmation = false,
    String title = 'تأكيد الخروج',
    String message = 'هل أنت متأكد من الخروج؟ سيتم فقدان البيانات غير المحفوظة.',
    String? fallbackRoute,
    VoidCallback? onBeforeNavigate,
  }) async {
    final canProceed = await confirmBackNavigation(
      context,
      needsConfirmation: needsConfirmation,
      title: title,
      message: message,
    );
    
    if (canProceed) {
      await navigateBack(
        context,
        fallbackRoute: fallbackRoute,
        onBeforeNavigate: onBeforeNavigate,
      );
    }
  }
  
  /// Setup a WillPopScope handler (for pre-Flutter 3.7)
  /// or PopScope.onPopInvoked handler (for Flutter 3.7+)
  static Future<bool> handleWillPop(
    BuildContext context, {
    bool needsConfirmation = false,
    String title = 'تأكيد الخروج',
    String message = 'هل أنت متأكد من الخروج؟ سيتم فقدان البيانات غير المحفوظة.',
    String? fallbackRoute,
    VoidCallback? onBeforeNavigate,
  }) async {
    final canProceed = await confirmBackNavigation(
      context,
      needsConfirmation: needsConfirmation,
      title: title,
      message: message,
    );
    
    if (canProceed) {
      if (onBeforeNavigate != null) {
        onBeforeNavigate();
      }
      
      if (fallbackRoute != null && context.mounted) {
        try {
          context.go(fallbackRoute);
          return false; // Prevent default pop behavior since we're handling navigation
        } catch (e) {
          print('Error navigating to fallback route: $e');
          // Fall through to return true
        }
      }
      
      return true; // Allow default pop behavior if we didn't handle navigation ourselves
    }
    
    return false; // Stay on current page (prevent pop)
  }
}