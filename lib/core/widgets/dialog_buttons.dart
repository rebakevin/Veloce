import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

const Size _buttonSize = Size.fromHeight(AppSizes.primaryButton);

/// The two buttons of a confirm dialog: Cancel and the confirming action on one
/// row, each half the width. Pass it as the only entry of `AlertDialog.actions`.
/// A null callback disables that button. [destructive] paints the confirm
/// button in the error colour.
class DialogButtons extends StatelessWidget {
  const DialogButtons({
    required this.confirmLabel,
    required this.onCancel,
    required this.onConfirm,
    super.key,
    this.cancelLabel = 'Cancel',
    this.destructive = false,
  });

  final String cancelLabel;
  final String confirmLabel;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: _buttonSize),
            onPressed: onCancel,
            child: Text(cancelLabel),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: _buttonSize,
              backgroundColor: destructive ? colors.error : null,
              foregroundColor: destructive ? colors.onError : null,
            ),
            onPressed: onConfirm,
            child: Text(confirmLabel),
          ),
        ),
      ],
    );
  }
}
