import 'package:flutter/material.dart';
import 'package:veloce/core/constants/app_constants.dart';
import 'package:veloce/core/domain/entities/long_rate.dart';
import 'package:veloce/core/domain/services/pricing_calculator.dart';
import 'package:veloce/core/formatting/formatters.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';

import '../../domain/entities/wizard_draft.dart';
import '../../domain/rules/wizard_step_rules.dart';
import 'draft_text_field.dart';

class PricingStep extends StatelessWidget {
  const PricingStep({
    required this.draft,
    required this.errors,
    required this.onChanged,
    super.key,
    this.calculator = const PricingCalculator(),
  });

  final WizardDraft draft;
  final Map<WizardField, String> errors;
  final ValueChanged<WizardDraft> onChanged;
  final PricingCalculator calculator;

  void _replaceTier(int index, LongRate tier) {
    final tiers = [...draft.longRates];
    tiers[index] = tier;
    onChanged(draft.copyWith(longRates: tiers));
  }

  void _removeTier(int index) {
    final tiers = [...draft.longRates]..removeAt(index);
    onChanged(draft.copyWith(longRates: tiers));
  }

  void _addTier() {
    onChanged(
      draft.copyWith(
        longRates: [
          ...draft.longRates,
          const LongRate(fromDays: 0, pricePerDay: 0),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tiers = draft.longRates;
    final tiersError = errors[WizardField.longRates];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DraftTextField(
          label: 'Price per day (RWF)',
          hint: '50000',
          initialValue: draft.dailyPrice?.toString() ?? '',
          errorText: errors[WizardField.dailyPrice],
          keyboardType: TextInputType.number,
          onChanged: (value) =>
              onChanged(draft.copyWith(dailyPrice: parseWhole(value))),
        ),
        const SizedBox(height: AppSpacing.lg),
        DraftTextField(
          label: 'Caution fee (RWF)',
          hint: '50000',
          initialValue: draft.cautionFee?.toString() ?? '',
          errorText: errors[WizardField.cautionFee],
          keyboardType: TextInputType.number,
          onChanged: (value) =>
              onChanged(draft.copyWith(cautionFee: parseWhole(value))),
        ),
        const SizedBox(height: AppSpacing.xl),
        const Text('Long-rental prices', style: AppTextStyles.cardTitle),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Longer rentals can cost less per day. Add up to '
          '${AppConstants.maxLongRates} prices.',
        ),
        const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < tiers.length; i++)
          _TierRow(
            key: ValueKey('tier-$i-${tiers.length}'),
            tier: tiers[i],
            onChanged: (tier) => _replaceTier(i, tier),
            onRemove: () => _removeTier(i),
          ),
        if (tiersError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              tiersError,
              style: AppTextStyles.bodySmall.copyWith(
                color: context.colors.danger,
              ),
            ),
          ),
        if (tiers.length < AppConstants.maxLongRates)
          OutlinedButton.icon(
            onPressed: _addTier,
            icon: const Icon(Icons.add),
            label: const Text('Add a long-rental price'),
          ),
        _Preview(draft: draft, calculator: calculator),
      ],
    );
  }
}

class _TierRow extends StatelessWidget {
  const _TierRow({
    required this.tier,
    required this.onChanged,
    required this.onRemove,
    super.key,
  });

  final LongRate tier;
  final ValueChanged<LongRate> onChanged;
  final VoidCallback onRemove;

  String? get _example {
    if (tier.fromDays < 1 || tier.pricePerDay < 1) return null;
    final total = tier.fromDays * tier.pricePerDay;
    return '${tier.fromDays} days: ${tier.fromDays} × '
        '${Formatters.rwf(tier.pricePerDay)} = ${Formatters.rwf(total)}';
  }

  @override
  Widget build(BuildContext context) {
    final example = _example;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: DraftTextField(
                  label: 'From (days)',
                  hint: '5',
                  initialValue: tier.fromDays == 0 ? '' : '${tier.fromDays}',
                  keyboardType: TextInputType.number,
                  onChanged: (value) =>
                      onChanged(tier.copyWith(fromDays: parseWhole(value))),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: DraftTextField(
                  label: 'Price per day',
                  hint: '45000',
                  initialValue: tier.pricePerDay == 0
                      ? ''
                      : '${tier.pricePerDay}',
                  keyboardType: TextInputType.number,
                  onChanged: (value) =>
                      onChanged(tier.copyWith(pricePerDay: parseWhole(value))),
                ),
              ),
              IconButton(
                tooltip: 'Remove price',
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          if (example != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(example, style: AppTextStyles.bodySmall),
            ),
        ],
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.draft, required this.calculator});

  final WizardDraft draft;
  final PricingCalculator calculator;

  @override
  Widget build(BuildContext context) {
    final dailyPrice = draft.dailyPrice;
    if (dailyPrice == null || dailyPrice < 1) return const SizedBox.shrink();
    final quote = calculator.quote(
      dailyPrice: dailyPrice,
      longRates: draft.longRates,
      cautionFee: draft.cautionFee ?? 0,
      start: DateTime(2026),
      end: DateTime(2026, 1, 4),
    );
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Preview for 3 days', style: AppTextStyles.cardTitle),
              const SizedBox(height: AppSpacing.sm),
              Text('Rental: ${Formatters.rwf(quote.rentalFee)}'),
              Text(
                'Renter pays in total: ${Formatters.rwf(quote.totalPayable)} '
                '(rental plus the refundable caution)',
              ),
              Text('You receive: ${Formatters.rwf(quote.ownerReceives)}'),
            ],
          ),
        ),
      ),
    );
  }
}