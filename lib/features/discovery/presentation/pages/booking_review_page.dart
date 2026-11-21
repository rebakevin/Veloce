import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:veloce/core/formatting/formatters.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/empty_state.dart';
import 'package:veloce/core/widgets/page_app_bar.dart';
import 'package:veloce/core/widgets/price_breakdown.dart';
import 'package:veloce/core/widgets/primary_button.dart';

import '../../domain/entities/booking_request_draft.dart';
import '../bloc/request_bloc.dart';
import '../widgets/booking_terms.dart';
import '../widgets/info_card.dart';
import '../widgets/label_value_row.dart';

/// Review step before the booking request is written.
class BookingReviewPage extends StatelessWidget {
  const BookingReviewPage({required this.vehicleId, super.key, this.draft});

  final String vehicleId;
  final BookingRequestDraft? draft;

  @override
  Widget build(BuildContext context) {
    final draft = this.draft;
    if (draft == null) {
      return const Scaffold(
        appBar: PageAppBar(title: 'Review request'),
        body: EmptyState(
          icon: Icons.event_busy_outlined,
          title: 'Choose dates first',
          message: 'Open the car and pick the dates you want to rent.',
        ),
      );
    }
    return BlocProvider<RequestBloc>(
      create: (_) => GetIt.instance<RequestBloc>(param1: draft),
      child: const _ReviewBody(),
    );
  }
}

class _ReviewBody extends StatelessWidget {
  const _ReviewBody();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RequestBloc, RequestState>(
      listener: (context, state) {
        if (state case RequestSuccess(:final booking, :final priceChanged)) {
          if (priceChanged) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'The owner changed the price. Your request total is '
                  '${Formatters.rwf(booking.totalPayable)}.',
                ),
              ),
            );
          }
          context.pushReplacement(RouteNames.bookingRequested(booking.id));
        }
      },
      builder: (context, state) {
        final editing = state is RequestEditing ? state : null;
        if (editing == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final draft = editing.draft;
        final vehicle = draft.vehicle;
        final colors = context.colors;
        return Scaffold(
          appBar: const PageAppBar(title: 'Review request'),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              child: PrimaryButton(
                label: 'Send booking request',
                isLoading: editing.isSubmitting,
                onPressed: editing.termsAccepted
                    ? () => context.read<RequestBloc>().add(
                        const RequestSubmitted(),
                      )
                    : null,
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            children: [
              InfoCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${vehicle.make} ${vehicle.model} · ${vehicle.year}',
                      style: AppTextStyles.cardTitle.copyWith(
                        color: colors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      vehicle.neighbourhood,
                      style: AppTextStyles.caption.copyWith(
                        color: colors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md + 2),
              InfoCard(
                child: Column(
                  spacing: AppSpacing.md - 2,
                  children: [
                    LabelValueRow(
                      label: 'Pickup',
                      value: Formatters.date(draft.start),
                    ),
                    LabelValueRow(
                      label: 'Return',
                      value: Formatters.date(draft.end),
                    ),
                    LabelValueRow(
                      label: 'Location',
                      value: '${vehicle.neighbourhood}, Kigali',
                    ),
                    LabelValueRow(
                      label: 'Duration',
                      value:
                          '${draft.quote.days} day${draft.quote.days == 1 ? '' : 's'}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md + 2),
              InfoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cost',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: colors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    PriceBreakdown(quote: draft.quote),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md + 2),
              if (vehicle.rulesFileUrl != null) ...[
                InfoCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Owner’s rental instructions',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: colors.ink,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () => unawaited(
                          launchUrl(
                            Uri.parse(vehicle.rulesFileUrl!),
                            mode: LaunchMode.externalApplication,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, AppSizes.iconControl),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                        ),
                        child: const Text('Download'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md + 2),
              ],
              BookingTerms(
                accepted: editing.termsAccepted,
                onChanged: (value) =>
                    context.read<RequestBloc>().add(RequestTermsChanged(value)),
              ),
              TextButton.icon(
                onPressed: () => context.push(RouteNames.user(vehicle.ownerId)),
                icon: const Icon(Icons.person_outline),
                label: const Text('View owner profile'),
              ),
              if (editing.failureMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.dangerWash,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      editing.failureMessage!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: colors.danger,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
