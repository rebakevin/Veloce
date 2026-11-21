import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:veloce/core/constants/app_constants.dart';
import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/formatting/formatters.dart';
import 'package:veloce/core/layout/responsive.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/app_messenger.dart';
import 'package:veloce/core/widgets/error_view.dart';
import 'package:veloce/core/widgets/loading_view.dart';
import 'package:veloce/core/widgets/page_app_bar.dart';
import 'package:veloce/core/widgets/primary_button.dart';
import 'package:veloce/core/widgets/status_chip.dart';

import '../bloc/booking_detail_bloc.dart';
import '../widgets/booking_card.dart';

/// Rental agreement with its nine sections and the renter's acknowledgement.
class AgreementPage extends StatelessWidget {
  const AgreementPage({required this.bookingId, super.key});

  final String bookingId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BookingDetailBloc>(
      create: (_) =>
          GetIt.instance<BookingDetailBloc>(param1: bookingId)
            ..add(const BookingDetailStarted()),
      child: AgreementView(bookingId: bookingId),
    );
  }
}

class AgreementView extends StatelessWidget {
  const AgreementView({required this.bookingId, super.key});

  final String bookingId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PageAppBar(title: 'Rental agreement'),
      body: BlocConsumer<BookingDetailBloc, BookingDetailState>(
        listenWhen: (previous, current) {
          if (current is! BookingDetailLoaded) return false;
          if (current.action.kind != BookingDetailActionKind.agreement) {
            return false;
          }
          if (!_finished(current.action.status)) return false;
          return previous is! BookingDetailLoaded ||
              previous.action != current.action;
        },
        listener: (context, state) {
          if (state is! BookingDetailLoaded) return;
          final action = state.action;
          final messenger = GetIt.instance<AppMessenger>();
          if (action.status == BookingDetailActionStatus.success) {
            messenger.success('Agreement accepted.');
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
          BookingDetailLoaded() => _AgreementBody(state: state),
        },
      ),
    );
  }

  static bool _finished(BookingDetailActionStatus status) =>
      status == BookingDetailActionStatus.success ||
      status == BookingDetailActionStatus.failure;
}

class _AgreementBody extends StatelessWidget {
  const _AgreementBody({required this.state});

  final BookingDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    final view = state.view;
    final booking = view.booking;
    final vehicle = view.vehicle;
    final role = state.role;
    final colors = context.colors;
    final canAck =
        role == UserRole.renter &&
        booking.agreementAckAt == null &&
        (view.effectiveStatus == BookingStatus.approved ||
            view.effectiveStatus == BookingStatus.confirmed);
    final ackAt = booking.agreementAckAt;

    return ListView(
      padding: Responsive.pagePadding(context)
          .copyWith(top: AppSpacing.lg, bottom: AppSpacing.xl),
      children: [
        StatusChip.booking(view.effectiveStatus),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Rental agreement · ${booking.reference}',
          style: AppTextStyles.title.copyWith(color: colors.ink),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Review these terms before pickup. The renter accepts the agreement '
          'in the app.',
          style: AppTextStyles.body.copyWith(color: colors.muted),
        ),
        const SizedBox(height: AppSpacing.xl),
        BookingCard(
          child: Column(
            children: [
              _AgreementSection(
                number: 1,
                title: 'Parties',
                body:
                    'Renter: ${view.renter.name}. Car owner: ${view.owner.name}. '
                    'Both parties are identified by their Veloce account.',
              ),
              _AgreementSection(
                number: 2,
                title: 'Vehicle',
                body:
                    '${vehicle.make} ${vehicle.model} (${vehicle.year}), plate '
                    '${vehicle.plate}. The renter confirms the car matches the '
                    'listing at handover.',
              ),
              _AgreementSection(
                number: 3,
                title: 'Rental period',
                body:
                    'From ${Formatters.date(booking.startDate)} to '
                    '${Formatters.date(booking.endDate)}: ${booking.days} '
                    'charged day${booking.days == 1 ? '' : 's'}. The return day is '
                    'not charged.',
              ),
              _AgreementSection(
                number: 4,
                title: 'Rental fee and caution',
                body:
                    'Rental fee: ${Formatters.rwf(booking.rentalFee)}. Refundable '
                    'caution fee: ${Formatters.rwf(booking.cautionFee)}. Total '
                    'payable: ${Formatters.rwf(booking.totalPayable)}.',
              ),
              _AgreementSection(
                number: 5,
                title: 'Payment',
                body:
                    'Veloce holds the full amount. The rental fee is released to the '
                    'owner only after both sides confirm pickup, minus the '
                    '${Formatters.rwf(booking.platformFee)} platform fee. The caution '
                    'fee is settled after the return.',
              ),
              _AgreementSection(
                number: 6,
                title: 'Fuel, smoking and extras',
                body:
                    '${vehicle.fuelRule}. ${vehicle.smoking}. '
                    '${vehicle.extras.isEmpty ? 'No extra items are included.' : 'Included: ${vehicle.extras.join(', ')}.'}',
              ),
              const _AgreementSection(
                number: 7,
                title: 'Late return',
                body:
                    'A late return costs 30% of the rental fee per late day, '
                    'compounding. The late fee and any damage claim cannot exceed '
                    'the caution fee. Anything above that is settled outside the app.',
              ),
              const _AgreementSection(
                number: 8,
                title: 'Cancellation',
                body:
                    'Either side can cancel until both sides confirm pickup. The '
                    'renter is refunded everything paid, with no platform fee. After '
                    'both confirm pickup there is no cancellation.',
              ),
              const _AgreementSection(
                number: 9,
                title: 'Contact and handover',
                body:
                    'Phone, email and the exact meeting point unlock for both sides '
                    'after payment. Identity documents and the owner payout number '
                    'are never shown. For help, contact ${AppConstants.supportEmail}.',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        BookingCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ackAt == null
                    ? 'Agreement not accepted yet'
                    : 'Accepted on ${Formatters.dateTime(ackAt)}',
                style: AppTextStyles.cardTitle,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                role == UserRole.owner
                    ? 'The renter accepts the agreement before pickup.'
                    : canAck
                    ? 'Accept the agreement to continue with this rental.'
                    : 'The agreement can be accepted after approval and '
                          'before pickup.',
                style: AppTextStyles.body,
              ),
              if (canAck) ...[
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  label: 'Accept agreement',
                  isLoading: state.action.isSubmitting,
                  onPressed: state.action.isSubmitting
                      ? null
                      : () => context.read<BookingDetailBloc>().add(
                          const BookingDetailAgreementAcknowledged(),
                        ),
                ),
              ],
            ],
          ),
        ),
        if (state.action.status == BookingDetailActionStatus.failure) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            state.action.message ?? 'Something went wrong.',
            style: AppTextStyles.body.copyWith(color: colors.danger),
          ),
        ],
      ],
    );
  }
}

class _AgreementSection extends StatelessWidget {
  const _AgreementSection({
    required this.number,
    required this.title,
    required this.body,
  });

  final int number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number. $title',
            style: AppTextStyles.bodySmall.copyWith(
              color: colors.brand,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            body,
            style: AppTextStyles.bodySmall.copyWith(color: colors.inkSoft),
          ),
        ],
      ),
    );
  }
}
