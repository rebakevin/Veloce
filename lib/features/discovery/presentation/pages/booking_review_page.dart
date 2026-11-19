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
        if (state case RequestSuccess(:final booking)) {
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
              Text(
                '${vehicle.make} ${vehicle.model} · ${vehicle.year}',
                style: AppTextStyles.title,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                vehicle.neighbourhood,
                style: AppTextStyles.bodySmall.copyWith(color: colors.muted),
              ),
              const SizedBox(height: AppSpacing.lg),
              _Row(label: 'Pickup', value: Formatters.date(draft.start)),
              _Row(label: 'Return', value: Formatters.date(draft.end)),
              _Row(
                label: 'Rental days',
                value:
                    '${draft.quote.days} day${draft.quote.days == 1 ? '' : 's'}',
              ),
              const SizedBox(height: AppSpacing.lg),
              PriceBreakdown(quote: draft.quote),
              const SizedBox(height: AppSpacing.lg),
              BookingTerms(
                accepted: editing.termsAccepted,
                onChanged: (value) =>
                    context.read<RequestBloc>().add(RequestTermsChanged(value)),
              ),
              if (vehicle.rulesFileUrl != null)
                TextButton.icon(
                  onPressed: () {
                    unawaited(
                      launchUrl(
                        Uri.parse(vehicle.rulesFileUrl!),
                        mode: LaunchMode.externalApplication,
                      ),
                    );
                  },
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Open rental instructions PDF'),
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

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: context.colors.muted,
              ),
            ),
          ),
          Text(value, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}
