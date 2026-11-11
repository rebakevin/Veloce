import 'package:flutter/material.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';

import '../bloc/profile_bloc.dart';

/// Inline result of the latest submission of [kind]: nothing unless it ended
/// with a problem, in which case the message is shown (and announced).
class ActionMessageBanner extends StatelessWidget {
  const ActionMessageBanner({
    required this.action,
    required this.kind,
    super.key,
  });

  final ProfileAction action;
  final ProfileActionKind kind;

  @override
  Widget build(BuildContext context) {
    final message = action.message;
    final failed = switch (action.status) {
      ProfileActionStatus.invalid ||
      ProfileActionStatus.failure ||
      ProfileActionStatus.verificationFailed => true,
      _ => false,
    };
    if (action.kind != kind || !failed || message == null) {
      return const SizedBox.shrink();
    }
    final colors = context.colors;
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.dangerWash,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: colors.danger),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.bodySmall.copyWith(color: colors.danger),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
