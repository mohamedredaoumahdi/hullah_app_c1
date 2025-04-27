// lib/core/widgets/custom_back_button.dart

import 'package:flutter/material.dart';
import '../utils/back_navigation_manager.dart';

class CustomBackButton extends StatelessWidget {
  final bool needsConfirmation;
  final String title;
  final String message;
  final String? fallbackRoute;
  final VoidCallback? onBeforeNavigate;
  
  const CustomBackButton({
    Key? key,
    this.needsConfirmation = false,
    this.title = 'تأكيد الخروج',
    this.message = 'هل أنت متأكد من الخروج؟ سيتم فقدان البيانات غير المحفوظة.',
    this.fallbackRoute,
    this.onBeforeNavigate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => BackNavigationManager.handleBackButton(
        context,
        needsConfirmation: needsConfirmation,
        title: title,
        message: message,
        fallbackRoute: fallbackRoute,
        onBeforeNavigate: onBeforeNavigate,
      ),
    );
  }
}