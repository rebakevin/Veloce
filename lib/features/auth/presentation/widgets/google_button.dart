import 'package:flutter/material.dart';

import 'package:veloce/core/theme/app_colors.dart';

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
    final colors = context.colors;
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.ink,
        side: BorderSide(color: colors.line, width: 1.5),
      ),
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          : const _GoogleMark(),
      label: Text(label),
    );
  }
}

/// The Google "G" in the brand blue, on a white disc.
class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  static const Color _googleBlue = Color(0xFF4285F4);

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: SizedBox.square(
        dimension: 22,
        child: Center(
          child: Text(
            'G',
            style: TextStyle(
              color: _googleBlue,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}
