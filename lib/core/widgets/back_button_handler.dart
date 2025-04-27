// lib/core/widgets/back_button_handler.dart
import 'package:flutter/material.dart';
import '../utils/navigation_utils.dart';

class BackButtonHandler extends StatelessWidget {
  final Widget child;
  final String title;
  final bool shouldConfirm;
  final String confirmationTitle;
  final String confirmationMessage;
  final VoidCallback? onWillPop;
  final List<Widget>? actions;
  final bool centerTitle;
  
  const BackButtonHandler({
    super.key,
    required this.child,
    required this.title,
    this.shouldConfirm = false,
    this.confirmationTitle = 'تأكيد الخروج',
    this.confirmationMessage = 'هل أنت متأكد من الخروج؟ سيتم فقدان البيانات غير المحفوظة.',
    this.onWillPop,
    this.actions,
    this.centerTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (!shouldConfirm) {
          if (onWillPop != null) onWillPop!();
          return true;
        }
        
        final result = await context.showNavigationConfirmation(
          title: confirmationTitle,
          message: confirmationMessage,
        );
        
        if (result) {
          if (onWillPop != null) onWillPop!();
          return true;
        }
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () async {
              if (!shouldConfirm) {
                if (onWillPop != null) onWillPop!();
                context.safeNavigateBack();
                return;
              }
              
              final result = await context.showNavigationConfirmation(
                title: confirmationTitle,
                message: confirmationMessage,
              );
              
              if (result) {
                if (onWillPop != null) onWillPop!();
                context.safeNavigateBack();
              }
            },
          ),
          title: Text(title),
          centerTitle: centerTitle,
          actions: actions,
        ),
        body: child,
      ),
    );
  }
}