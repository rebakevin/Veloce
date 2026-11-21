import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:veloce/core/layout/responsive.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/page_app_bar.dart';
import 'package:veloce/core/widgets/primary_button.dart';

import '../widgets/booking_card.dart';

/// Payment success with the simulated MoMo reference.
class PaymentResultPage extends StatelessWidget {
  const PaymentResultPage({
    required this.bookingId,
    super.key,
    this.reference,
    this.bookingReference,
  });

  final String bookingId;
  final String? reference;
  final String? bookingReference;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: const PageAppBar(title: 'Payment'),
      body: ListView(
        padding: Responsive.pagePadding(context)
            .copyWith(top: AppSpacing.xl, bottom: AppSpacing.xl),
        children: [
          BookingCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: 28,
            ),
            child: Column(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.brandTint,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: Icon(Icons.check, size: 36, color: colors.brandDeep),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'Payment successful',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.title,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'The booking is confirmed and the contact details are '
                  'unlocked.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(color: colors.muted),
                ),
                const SizedBox(height: AppSpacing.md),
                if (bookingReference != null)
                  _Row(label: 'Booking', value: bookingReference!),
                if (reference != null)
                  _Row(label: 'MoMo reference', value: reference!),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'View booking',
            onPressed: () => context.go(RouteNames.booking(bookingId)),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.body.copyWith(color: context.colors.muted),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTextStyles.cardTitle,
            ),
          ),
        ],
      ),
    );
  }
}
