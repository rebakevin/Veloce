import 'package:flutter/material.dart';

import 'package:veloce/core/theme/app_spacing.dart';

/// A "Continue with Google" style button. The sign-in itself runs in
/// `LoginBloc`.
class GoogleButton extends StatelessWidget {
  const GoogleButton({
    required this.onPressed,
    super.key,
    this.isLoading = false,
    this.label = 'Continue with Google',
  });

  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          : const Icon(Icons.g_mobiledata, size: AppSpacing.xl + AppSpacing.sm),
      label: Text(label),
    );
  }
}
