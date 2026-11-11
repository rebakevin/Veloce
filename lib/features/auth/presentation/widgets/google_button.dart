import 'package:flutter/material.dart';

import 'package:veloce/core/theme/app_spacing.dart';

/// "Continue with Google". The sign-in itself runs in `LoginBloc`.
class GoogleButton extends StatelessWidget {
  const GoogleButton({
    required this.onPressed,
    super.key,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final bool isLoading;

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
      label: const Text('Continue with Google'),
    );
  }
}
