import 'package:flutter/material.dart';

import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/widgets/app_back_button.dart';

/// Page frame shared by the auth screens: safe area, side gutter, a centred
/// column that scrolls (so landscape and large text never overflow). Content
/// starts at the top; set [centered] for a lone message such as the splash.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    required this.child,
    super.key,
    this.title,
    this.onBack,
    this.centered = false,
  });

  static const double maxContentWidth = 480;

  final Widget child;
  final String? title;

  /// Shows a back button in the app bar when set.
  final VoidCallback? onBack;

  /// Centres the content vertically instead of starting at the top.
  final bool centered;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: title == null && onBack == null
          ? null
          : AppBar(
              title: title == null ? null : Text(title!),
              leading: onBack == null
                  ? null
                  : AppBackButton(onPressed: onBack!),
            ),
      body: SafeArea(
        child: Align(
          alignment: centered ? Alignment.center : Alignment.topCenter,
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
