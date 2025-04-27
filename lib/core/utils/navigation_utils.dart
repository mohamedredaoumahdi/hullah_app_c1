// lib/core/utils/navigation_utils.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Extension methods for navigation helpers
extension NavigationExtensions on BuildContext {
  /// Safely pops the current route
  /// 
  /// This is a simplified version that avoids multiple navigation attempts
  void safeNavigateBack() {
    if (Navigator.canPop(this)) {
      Navigator.of(this).pop();
    }
  }
  
  /// Shows a confirmation dialog before navigating back
  ///
  /// Returns true if the user confirmed, false otherwise
  Future<bool> showNavigationConfirmation({
    String title = 'تأكيد الخروج',
    String message = 'هل أنت متأكد من الخروج؟ سيتم فقدان البيانات غير المحفوظة.',
  }) async {
    final result = await showDialog<bool>(
      context: this,
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
  
  /// Confirms before navigating back if needed
  ///
  /// If [shouldConfirm] is true, shows a confirmation dialog first
  Future<void> safeNavigateBackWithConfirmation({
    bool shouldConfirm = false,
    String title = 'تأكيد الخروج',
    String message = 'هل أنت متأكد من الخروج؟ سيتم فقدان البيانات غير المحفوظة.',
    VoidCallback? onWillPop,
  }) async {
    if (!shouldConfirm) {
      if (onWillPop != null) onWillPop();
      safeNavigateBack();
      return;
    }
    
    final confirmed = await showNavigationConfirmation(
      title: title,
      message: message,
    );
    
    if (confirmed) {
      if (onWillPop != null) onWillPop();
      safeNavigateBack();
    }
  }
}