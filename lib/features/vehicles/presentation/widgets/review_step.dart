import 'package:flutter/material.dart';
import 'package:veloce/core/domain/enums/document_kind.dart';
import 'package:veloce/core/formatting/formatters.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';

import '../../domain/entities/wizard_draft.dart';

class ReviewStep extends StatelessWidget {
  const ReviewStep({required this.draft, super.key});

  final WizardDraft draft;

  String _document(DocumentKind kind) {
    final document = draft.documents[kind];
    final expiry = document?.expiry;
    if (document?.photo == null || expiry == null) {
      return '${kind.label}: Not added';
    }
    return '${kind.label}: valid until ${Formatters.date(expiry)}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Section(
          title: 'Car',
          lines: [
            '${draft.make} ${draft.model} · ${draft.year}',
            draft.plate.trim().toUpperCase(),
            '${draft.type?.label} · ${draft.transmission?.label} · '
                '${draft.fuel?.label} · ${draft.seats} seats',
            'Pickup: ${draft.neighbourhood}',
          ],
        ),
        _Section(
          title: 'Pricing',
          lines: [
            '${Formatters.rwf(draft.dailyPrice ?? 0)} per day',
            for (final tier in draft.longRates)
              '${tier.fromDays}+ days: ${Formatters.rwf(tier.pricePerDay)} '
                  'per day',
            'Caution: ${Formatters.rwf(draft.cautionFee ?? 0)}',
          ],
        ),
        _Section(title: 'Photos', lines: ['${draft.photos.length} photos']),
        _Section(
          title: 'Documents',
          lines: [for (final kind in DocumentKind.values) _document(kind)],
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: SizedBox(
        width: double.infinity,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.cardTitle),
                const SizedBox(height: AppSpacing.sm),
                for (final line in lines) Text(line),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
