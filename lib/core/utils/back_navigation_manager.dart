// lib/core/utils/back_navigation_manager.dart

import 'package:flutter/material.dart';
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
  
  /// Navigate back to a specific route
  static void navigateBack(
    BuildContext context, {
    String? fallbackRoute,
    VoidCallback? onBeforeNavigate,
  }) {
    // Execute optional callback
    if (onBeforeNavigate != null) {
      onBeforeNavigate();
    }
    
    // Try to pop current route
    try {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
        return;
      } 
    } catch (e) {
      print('Error popping route: $e');
    }
    
    // If popping fails or can't pop, and fallback provided, use it
    if (fallbackRoute != null) {
      try {
        context.go(fallbackRoute);
      } catch (e) {
        print('Error navigating to fallback: $e');
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
      navigateBack(
        context,
        fallbackRoute: fallbackRoute,
        onBeforeNavigate: onBeforeNavigate,
      );
    }
  }
  
  /// Setup a WillPopScope handler
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
      
      if (fallbackRoute != null) {
        if (context.mounted) {
          context.go(fallbackRoute);
        }
        return false; // Prevent default pop behavior
      }
      
      return true; // Allow default pop behavior
    }
    
    return false; // Stay on current page
  }
}