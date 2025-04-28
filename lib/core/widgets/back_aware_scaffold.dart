import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// A Scaffold that is aware of back navigation actions and can handle them gracefully.
/// 
/// This widget handles back button presses, swipe gestures, and provides a confirmation
/// dialog when needed. It's designed to work with GoRouter for navigation.
class BackAwareScaffold extends StatefulWidget {
  /// The title displayed in the app bar
  final String title;
  
  /// The main content of the scaffold
  final Widget body;
  
  /// Additional actions for the app bar
  final List<Widget>? actions;
  
  /// Optional floating action button
  final Widget? floatingActionButton;
  
  /// Whether to show a back button in the app bar
  final bool showBackButton;
  
  /// Whether to show a drawer
  final bool showDrawer;
  
  /// Whether to show a confirmation dialog when navigating back
  final bool confirmOnBack;
  
  /// Title for the confirmation dialog
  final String confirmationTitle;
  
  /// Message for the confirmation dialog
  final String confirmationMessage;
  
  /// Route to navigate to if normal back navigation fails
  final String? fallbackRoute;
  
  /// Callback to execute before navigating back
  final VoidCallback? onBackPressed;
  
  /// Whether the scaffold should use RTL text direction
  final bool useRtl;
  
  /// Optional drawer widget
  final Widget? drawer;

  /// Creates a BackAwareScaffold
  const BackAwareScaffold({
    Key? key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.showBackButton = false,
    this.showDrawer = false,
    this.confirmOnBack = false,
    this.confirmationTitle = 'Confirm Exit',
    this.confirmationMessage = 'Are you sure you want to exit? Unsaved changes will be lost.',
    this.fallbackRoute,
    this.onBackPressed,
    this.useRtl = true,
    this.drawer,
  }) : super(key: key);

  @override
  State<BackAwareScaffold> createState() => _BackAwareScaffoldState();
}

class _BackAwareScaffoldState extends State<BackAwareScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.confirmOnBack,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        
        final result = await _showExitConfirmationDialog();
        if (result) {
          if (widget.onBackPressed != null) {
            widget.onBackPressed!();
          }
          
          if (context.mounted) {
            _handleBackNavigation();
          }
        }
      },
      child: Directionality(
        textDirection: widget.useRtl ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            title: Text(widget.title),
            centerTitle: true,
            actions: widget.actions,
            leading: widget.showBackButton 
              ? IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () => _handleBackButtonPressed(),
                )
              : widget.showDrawer 
                ? Builder(
                    builder: (context) => IconButton(
                      icon: Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  )
                : null,
          ),
          drawer: widget.drawer ?? (widget.showDrawer ? _buildDefaultDrawer() : null),
          body: widget.body,
          floatingActionButton: widget.floatingActionButton,
        ),
      ),
    );
  }

  Widget? _buildDefaultDrawer() {
    // Implement your default drawer here if needed
    return null;
  }

  void _handleBackButtonPressed() async {
    if (widget.confirmOnBack) {
      final result = await _showExitConfirmationDialog();
      if (!result) return;
    }
    
    if (widget.onBackPressed != null) {
      widget.onBackPressed!();
    }
    
    if (mounted) {
      _handleBackNavigation();
    }
  }

  Future<bool> _showExitConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.confirmationTitle),
        content: Text(widget.confirmationMessage),
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
    ) ?? false;
  }

  void _handleBackNavigation() {
    // First try regular Navigator.pop
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }
    
    // If we can't pop, try to use fallback route
    if (widget.fallbackRoute != null) {
      try {
        context.go(widget.fallbackRoute!);
      } catch (e) {
        // If go() fails, try push() as a fallback
        try {
          context.push(widget.fallbackRoute!);
        } catch (e) {
          // Log error but don't crash
          debugPrint('Error navigating to fallback route: $e');
          
          // Last resort - use system back
          SystemNavigator.pop();
        }
      }
    } else {
      // No fallback route specified, try to use system back
      SystemNavigator.pop();
    }
  }
}