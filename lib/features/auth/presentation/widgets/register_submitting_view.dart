import 'package:flutter/material.dart';

import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/loading_view.dart';

/// Shown while the final registration write runs, and its failure with Retry
/// (document check failed, email taken, offline) or a way back to the form.
class RegisterSubmittingView extends StatelessWidget {
  const RegisterSubmittingView({
    required this.isBusy,
    required this.onRetry,
    required this.onBack,
    super.key,
    this.message,
  });

  final bool isBusy;
  final String? message;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    if (isBusy) {
      return const Column(
        children: [
          SizedBox(height: AppSpacing.xl),
          SizedBox(height: 120, child: LoadingView()),
          Text('Creating your account...', style: AppTextStyles.bodyLarge),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xl),
        Icon(
          Icons.error_outline,
          size: 48,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          message ?? 'We could not finish creating your account.',
          style: AppTextStyles.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        FilledButton(onPressed: onRetry, child: const Text('Try again')),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton(onPressed: onBack, child: const Text('Edit my details')),
      ],
    );
  }
}
