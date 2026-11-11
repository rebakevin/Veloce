import 'package:flutter/material.dart';

import 'package:veloce/core/theme/app_spacing.dart';

/// Page frame shared by the auth screens: safe area, side gutter, a centred
/// column that scrolls (so landscape and large text never overflow).
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({required this.child, super.key, this.title, this.onBack});

  static const double maxContentWidth = 480;

  final Widget child;
  final String? title;

  /// Shows a back button in the app bar when set.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: title == null && onBack == null
          ? null
          : AppBar(
              title: title == null ? null : Text(title!),
              leading: onBack == null
                  ? null
                  : IconButton(
                      tooltip: 'Back',
                      icon: const Icon(Icons.arrow_back),
                      onPressed: onBack,
                    ),
            ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxContentWidth),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.gutter,
                vertical: AppSpacing.lg,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
