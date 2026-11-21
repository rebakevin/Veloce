import 'package:flutter/material.dart';

import 'package:veloce/core/formatting/formatters.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/primary_button.dart';

/// Shown while the final registration write runs (the identity check), and its
/// failure with Retry (document check failed, email taken, offline) or a way
/// back to the form. Both states list what was submitted.
class RegisterSubmittingView extends StatelessWidget {
  const RegisterSubmittingView({
    required this.isBusy,
    required this.onRetry,
    required this.onBack,
    super.key,
    this.message,
    this.isOwner = false,
    this.name = '',
    this.dateOfBirth,
    this.documentNumber = '',
    this.hasPhoto = false,
  });

  final bool isBusy;
  final String? message;
  final VoidCallback onRetry;
  final VoidCallback onBack;
  final bool isOwner;
  final String name;
  final DateTime? dateOfBirth;
  final String documentNumber;
  final bool hasPhoto;

  String get _document => isOwner ? 'National ID' : 'Driving licence';

  @override
  Widget build(BuildContext context) {
    final lower = _document.toLowerCase();
    final dob = dateOfBirth;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.sm),
        if (isBusy)
          _StatusCard(
            title: 'Verifying your $_document',
            text:
                'Checking your $lower photo and number. This takes a few '
                'seconds.',
          )
        else
          _FailureCard(
            title: 'We couldn’t verify your $lower',
            text:
                message ??
                'The photo didn’t match the number. Check the photo is sharp, '
                    'uncropped and in good light, and that the number is '
                    'correct.',
          ),
        const SizedBox(height: AppSpacing.lg),
        DecoratedBox(
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              spacing: AppSpacing.md - 2,
              children: [
                _SummaryRow(label: 'Name', value: name),
                _SummaryRow(
                  label: 'Date of birth',
                  value: dob == null ? '' : Formatters.date(dob),
                ),
                _SummaryRow(label: _document, value: _mask(documentNumber)),
                _SummaryRow(
                  label: 'Photo',
                  value: hasPhoto ? 'Attached' : 'Missing',
                ),
              ],
            ),
          ),
        ),
        if (!isBusy) ...[
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(label: 'Try again', onPressed: onRetry),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(onPressed: onBack, child: const Text('Edit details')),
        ],
      ],
    );
  }

  static String _mask(String number) => number.length <= 4
      ? number
      : '${'•' * (number.length - 4)}${number.substring(number.length - 4)}';
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sheet),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl - 4,
          vertical: AppSpacing.xl + 4,
        ),
        child: Column(
          children: [
            const SizedBox.square(
              dimension: 44,
              child: CircularProgressIndicator(strokeWidth: 4),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.title.copyWith(
                color: colors.ink,
                fontSize: 26,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              text,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: colors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _FailureCard extends StatelessWidget {
  const _FailureCard({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.dangerWash,
          borderRadius: BorderRadius.circular(AppRadius.sheet),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl - 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surface,
                  shape: BoxShape.circle,
                ),
                child: SizedBox.square(
                  dimension: 52,
                  child: Icon(Icons.close, color: colors.danger),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                style: AppTextStyles.title.copyWith(
                  color: colors.danger,
                  fontSize: 26,
                ),
              ),
              const SizedBox(height: AppSpacing.sm - 2),
              Text(
                text,
                style: AppTextStyles.body.copyWith(color: colors.danger),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.md - 2,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: colors.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTextStyles.bodySmall.copyWith(
              color: colors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
