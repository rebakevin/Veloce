import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/formatting/formatters.dart';
import 'package:veloce/core/layout/responsive.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/app_messenger.dart';
import 'package:veloce/core/widgets/error_view.dart';
import 'package:veloce/core/widgets/loading_view.dart';
import 'package:veloce/core/widgets/page_app_bar.dart';
import 'package:veloce/core/widgets/user_avatar.dart';
import 'package:veloce/features/handover/handover.dart';
import 'package:veloce/features/reviews/reviews.dart';

import '../../domain/entities/booking_view.dart';
import '../bloc/booking_detail_bloc.dart';
import '../widgets/booking_card.dart';
import '../widgets/booking_price_breakdown.dart';
import '../widgets/booking_status_headline.dart';
import '../widgets/booking_thumb.dart';
import '../widgets/booking_timeline.dart';
import '../widgets/cancel_booking_dialog.dart';
import '../widgets/counterparty_contact_card.dart';

/// Booking detail and timeline. Hosts the handover (Phase 5) and post-rental
/// (Phase 6) slots so those phases never edit this file.
class BookingDetailPage extends StatelessWidget {
  const BookingDetailPage({required this.bookingId, super.key});

  final String bookingId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BookingDetailBloc>(
      create: (_) =>
          GetIt.instance<BookingDetailBloc>(param1: bookingId)
            ..add(const BookingDetailStarted()),
      child: BookingDetailView(bookingId: bookingId),
    );
  }
}

class BookingDetailView extends StatelessWidget {
  const BookingDetailView({required this.bookingId, super.key});

  final String bookingId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PageAppBar(title: 'Booking'),
      body: BlocConsumer<BookingDetailBloc, BookingDetailState>(
        listenWhen: (previous, current) {
          if (current is! BookingDetailLoaded) return false;
          if (!_finished(current.action.status)) return false;
          return previous is! BookingDetailLoaded ||
              previous.action != current.action;
        },
        listener: (context, state) {
          if (state is! BookingDetailLoaded) return;
          final action = state.action;
          final messenger = GetIt.instance<AppMessenger>();
          if (action.status == BookingDetailActionStatus.success) {
            messenger.success(
              action.kind == BookingDetailActionKind.agreement
                  ? 'Agreement accepted.'
                  : 'Booking cancelled.',
            );
          } else {
            messenger.error(action.message ?? 'Something went wrong.');
          }
          context.read<BookingDetailBloc>().add(
            const BookingDetailActionAcknowledged(),
          );
        },
        builder: (context, state) => switch (state) {
          BookingDetailLoading() => const LoadingView(),
          BookingDetailFailure(:final failure) => ErrorView(
            message: failure.message,
            onRetry: () => context.read<BookingDetailBloc>().add(
              const BookingDetailStarted(),
            ),
          ),
          BookingDetailLoaded() => _BookingDetailBody(
            state: state,
            bookingId: bookingId,
          ),
        },
      ),
    );
  }

  static bool _finished(BookingDetailActionStatus status) =>
      status == BookingDetailActionStatus.success ||
      status == BookingDetailActionStatus.failure;
}

class _BookingDetailBody extends StatelessWidget {
  const _BookingDetailBody({required this.state, required this.bookingId});

  final BookingDetailLoaded state;
  final String bookingId;

  @override
  Widget build(BuildContext context) {
    final view = state.view;
    final booking = view.booking;
    final role = state.role;
    final colors = context.colors;
    final canCancel = switch (view.effectiveStatus) {
      BookingStatus.pending => role == UserRole.renter,
      BookingStatus.approved || BookingStatus.confirmed => true,
      _ => false,
    };

    final counterpart = view.counterpartFor(role);
    return ListView(
      padding: Responsive.pagePadding(context)
          .copyWith(top: AppSpacing.sm, bottom: AppSpacing.xl),
      children: [
        BookingCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BookingStatusHeadline(view: view, role: role),
              const SizedBox(height: AppSpacing.lg),
              BookingTimeline(status: view.effectiveStatus),
            ],
          ),
        ),
        const SizedBox(height: _gap),
        _CarRow(
          view: view,
          role: role,
          onTap: () => context.push(RouteNames.car(view.vehicle.id)),
        ),
        const SizedBox(height: _gap),
        _PersonCard(
          name: counterpart.name,
          photoUrl: counterpart.photoUrl,
          label: role == UserRole.owner ? 'Renter' : 'Owner',
          onTap: () => context.push(RouteNames.user(counterpart.id)),
        ),
        const SizedBox(height: _gap),
        CounterpartyContactCard(view: view, role: role, contact: state.contact),
        const SizedBox(height: _gap),
        BookingCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payment summary',
                style: AppTextStyles.cardTitle.copyWith(
                  color: colors.ink,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              BookingPriceBreakdown(
                booking: booking,
                showOwnerView: role == UserRole.owner,
              ),
              _InfoRow(
                label: 'Payment',
                value: _paymentStatus(view.effectiveStatus),
              ),
              _InfoRow(
                label: 'Caution fee',
                value: _cautionStatus(view.effectiveStatus),
              ),
              if (view.effectiveStatus == BookingStatus.approved &&
                  booking.payDeadline != null)
                _InfoRow(
                  label: 'Pay by',
                  value: Formatters.dateTime(booking.payDeadline!),
                ),
            ],
          ),
        ),
        const SizedBox(height: _gap),
        _AgreementRow(
          accepted: booking.agreementAckAt != null,
          onTap: () => context.push(RouteNames.bookingAgreement(bookingId)),
        ),
        const SizedBox(height: _gap),
        BookingCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dates',
                style: AppTextStyles.cardTitle.copyWith(
                  color: colors.ink,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              _InfoRow(
                label: 'Pickup',
                value: Formatters.date(booking.startDate),
              ),
              _InfoRow(
                label: 'Return',
                value: Formatters.date(booking.endDate),
              ),
              _InfoRow(
                label: 'Days',
                value: '${booking.days} day${booking.days == 1 ? '' : 's'}',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            if (role == UserRole.renter &&
                view.effectiveStatus == BookingStatus.approved)
              FilledButton(
                onPressed: actionDisabled(state)
                    ? null
                    : () => context.push(RouteNames.bookingPay(bookingId)),
                child: const Text('Pay now'),
              ),
            if (role == UserRole.owner &&
                view.effectiveStatus == BookingStatus.pending)
              FilledButton(
                onPressed: actionDisabled(state)
                    ? null
                    : () => context.push(RouteNames.bookingDecision(bookingId)),
                child: const Text('Review request'),
              ),
            if (canCancel)
              OutlinedButton(
                onPressed: actionDisabled(state)
                    ? null
                    : () => _cancel(context, view),
                child: const Text('Cancel'),
              ),
          ],
        ),
        if (switch (view.effectiveStatus) {
          BookingStatus.confirmed ||
          BookingStatus.active ||
          BookingStatus.returning ||
          BookingStatus.review => true,
          _ => false,
        }) ...[
          const SizedBox(height: AppSpacing.lg),
          HandoverSection(bookingId: bookingId),
        ],
        if (view.effectiveStatus == BookingStatus.completed) ...[
          const SizedBox(height: AppSpacing.lg),
          PostRentalSection(bookingId: bookingId),
        ],
      ],
    );
  }

  static const double _gap = 14;

  static bool actionDisabled(BookingDetailLoaded state) =>
      state.action.isSubmitting;

  Future<void> _cancel(BuildContext context, BookingView view) async {
    final bloc = context.read<BookingDetailBloc>();
    final confirmed = await showCancelBookingDialog(context, view);
    if (!confirmed || !context.mounted) return;
    bloc.add(const BookingDetailCancelRequested());
  }

  static String _paymentStatus(BookingStatus status) => switch (status) {
    BookingStatus.confirmed ||
    BookingStatus.active ||
    BookingStatus.returning ||
    BookingStatus.review ||
    BookingStatus.completed => 'Paid',
    BookingStatus.approved => 'Payment due',
    _ => 'Not paid',
  };

  static String _cautionStatus(BookingStatus status) => switch (status) {
    BookingStatus.confirmed ||
    BookingStatus.active ||
    BookingStatus.returning ||
    BookingStatus.review => 'Held by Veloce',
    BookingStatus.completed => 'Settled',
    _ => 'Not charged',
  };
}

class _CarRow extends StatelessWidget {
  const _CarRow({required this.view, required this.role, required this.onTap});

  final BookingView view;
  final UserRole role;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final booking = view.booking;
    final detail = AppTextStyles.caption.copyWith(color: colors.muted);
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              const BookingThumb(),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${view.vehicle.make} ${view.vehicle.model}',
                      style: AppTextStyles.cardTitle.copyWith(
                        color: colors.ink,
                      ),
                    ),
                    Text(
                      '${Formatters.dateRange(booking.startDate, booking.endDate)}'
                      ' · ${booking.days} day${booking.days == 1 ? '' : 's'}',
                      style: detail,
                    ),
                    Text(
                      '${view.vehicle.neighbourhood}, Kigali · '
                      '${view.vehicle.plate}',
                      style: detail,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgreementRow extends StatelessWidget {
  const _AgreementRow({required this.accepted, required this.onTap});

  final bool accepted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rental agreement',
                      style: AppTextStyles.cardTitle.copyWith(
                        color: colors.ink,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      accepted ? 'Accepted' : 'Not accepted',
                      style: AppTextStyles.caption.copyWith(
                        color: colors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.brand),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(color: colors.muted),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
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
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  const _PersonCard({
    required this.name,
    required this.label,
    required this.onTap,
    this.photoUrl,
  });

  final String name;
  final String? photoUrl;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      label: 'View $label profile',
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                UserAvatar(name: name, photoUrl: photoUrl, radius: 22),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppTextStyles.label.copyWith(
                          color: colors.muted,
                        ),
                      ),
                      Text(
                        name,
                        style: AppTextStyles.cardTitle.copyWith(
                          color: colors.ink,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: colors.brand),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
