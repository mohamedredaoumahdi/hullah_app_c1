// lib/core/widgets/reliable_back_button.dart

import 'package:flutter/material.dart';

class ReliableBackButton extends StatelessWidget {
  final VoidCallback? onBeforePop;
  final bool showConfirmation;
  final String confirmTitle;
  final String confirmMessage;
  
  const ReliableBackButton({
    Key? key,
    this.onBeforePop,
    this.showConfirmation = false,
    this.confirmTitle = 'تأكيد الخروج',
    this.confirmMessage = 'هل أنت متأكد من الخروج؟',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () async {
        // Call optional callback before navigating
        if (onBeforePop != null) {
          onBeforePop!();
        }
        
        // Show confirmation if needed
        if (showConfirmation) {
          final shouldPop = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(confirmTitle),
              content: Text(confirmMessage),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('إلغاء'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('خروج', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
          
          if (shouldPop != true) {
            return;
          }
        }
        
        // Simple navigation - avoid complex multi-attempts that can cause lock issues
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
      },
    );
  }
}