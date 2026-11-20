import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/core/formatting/formatters.dart';
import 'package:veloce/core/layout/responsive.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/validation/validators.dart';
import 'package:veloce/core/widgets/app_messenger.dart';
import 'package:veloce/core/widgets/app_text_field.dart';
import 'package:veloce/core/widgets/error_view.dart';
import 'package:veloce/core/widgets/field_hints.dart';
import 'package:veloce/core/widgets/loading_view.dart';
import 'package:veloce/core/widgets/page_app_bar.dart';
import 'package:veloce/core/widgets/primary_button.dart';
import 'package:veloce/core/widgets/section_header.dart';
import 'package:veloce/core/widgets/status_chip.dart';

import '../bloc/payment_bloc.dart';
import '../widgets/booking_price_breakdown.dart';

/// MoMo payment for an approved booking.
class PaymentPage extends StatelessWidget {
  const PaymentPage({required this.bookingId, super.key});

  final String bookingId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PaymentBloc>(
      create: (_) =>
          GetIt.instance<PaymentBloc>(param1: bookingId)
            ..add(const PaymentStarted()),
      child: PaymentView(bookingId: bookingId),
    );
  }
}

class PaymentView extends StatefulWidget {
  const PaymentView({required this.bookingId, super.key});

  final String bookingId;

  @override
  State<PaymentView> createState() => _PaymentViewState();
}

class _PaymentViewState extends State<PaymentView> {
  final _formKey = GlobalKey<FormState>();
  final _momoController = TextEditingController();

  @override
  void dispose() {
    _momoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PageAppBar(title: 'Payment'),
      body: BlocConsumer<PaymentBloc, PaymentState>(
        listenWhen: (previous, current) {
          if (current is! PaymentLoaded) return false;
          if (current.action.status != PaymentActionStatus.success) {
            return false;
          }
          return previous is! PaymentLoaded ||
              previous.action != current.action;
        },
        listener: (context, state) {
          if (state is! PaymentLoaded) return;
          final reference = state.action.reference;
          if (reference == null) return;
          GetIt.instance<AppMessenger>().success('Payment successful.');
          final uri = Uri(
            path: RouteNames.bookingPayResult(widget.bookingId),
            queryParameters: {
              'reference': reference,
              'booking': state.view.booking.reference,
            },
          );
          context.go(uri.toString());
        },
        builder: (context, state) => switch (state) {
          PaymentLoading() => const LoadingView(),
          PaymentFailure(:final failure) => ErrorView(
            message: failure.message,
            onRetry: () =>
                context.read<PaymentBloc>().add(const PaymentStarted()),
          ),
          PaymentLoaded() => _PaymentBody(
            state: state,
            formKey: _formKey,
            momoController: _momoController,
          ),
        },
      ),
    );
  }
}

class _PaymentBody extends StatelessWidget {
  const _PaymentBody({
    required this.state,
    required this.formKey,
    required this.momoController,
  });

  final PaymentLoaded state;
  final GlobalKey<FormState> formKey;
  final TextEditingController momoController;

  @override
  Widget build(BuildContext context) {
    final view = state.view;
    final booking = view.booking;
    final action = state.action;
    final colors = context.colors;
    final deadline = booking.payDeadline;
    final hasDeadline = deadline != null;

    if (view.effectiveStatus != BookingStatus.approved) {
      return ListView(
        padding: Responsive.pagePadding(context)
            .copyWith(top: AppSpacing.lg, bottom: AppSpacing.xl),
        children: [
          Center(child: StatusChip.booking(view.effectiveStatus)),
          const SizedBox(height: AppSpacing.lg),
          Text(
            _closedMessage(view.effectiveStatus),
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: OutlinedButton(
              onPressed: () => context.go(RouteNames.booking(booking.id)),
              child: const Text('View booking'),
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: Responsive.pagePadding(context)
          .copyWith(top: AppSpacing.lg, bottom: AppSpacing.xl),
      children: [
        Text(
          '${view.vehicle.make} ${view.vehicle.model} · ${view.vehicle.plate}',
          style: AppTextStyles.cardTitle,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          Formatters.dateRange(booking.startDate, booking.endDate),
          style: AppTextStyles.body,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (hasDeadline) _DeadlineCard(deadline: deadline),
        const SizedBox(height: AppSpacing.lg),
        const SectionHeader(title: 'Total'),
        BookingPriceBreakdown(booking: booking),
        const SizedBox(height: AppSpacing.lg),
        const SectionHeader(title: 'Mobile Money'),
        Form(
          key: formKey,
          child: AppTextField(
            label: 'MoMo number',
            hint: FieldHints.momoNumber,
            controller: momoController,
            keyboardType: TextInputType.number,
            validator: Validators.momoNumber,
          ),
        ),
        if (action.status == PaymentActionStatus.failure) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            action.message ?? 'The payment was not approved. Please try again.',
            style: AppTextStyles.body.copyWith(color: colors.danger),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        _PayButton(
          deadline: deadline,
          isProcessing: action.isProcessing,
          label: Formatters.rwf(booking.totalPayable),
          onPressed: action.isProcessing
              ? null
              : () {
                  if (!(formKey.currentState?.validate() ?? false)) return;
                  context.read<PaymentBloc>().add(
                    PaymentSubmitted(momoController.text.trim()),
                  );
                },
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Simulated MTN MoMo. The money is held by Veloce until both sides '
          'confirm pickup.',
          textAlign: TextAlign.center,
          style: AppTextStyles.caption.copyWith(color: colors.muted),
        ),
      ],
    );
  }

  static String _closedMessage(BookingStatus status) => switch (status) {
    BookingStatus.confirmed ||
    BookingStatus.active ||
    BookingStatus.returning ||
    BookingStatus.review ||
    BookingStatus.completed => 'This booking is already paid.',
    BookingStatus.expired => 'The payment deadline has passed.',
    BookingStatus.cancelled => 'This booking was cancelled.',
    BookingStatus.declined => 'This request was declined.',
    BookingStatus.pending => 'The owner has not approved this request yet.',
    BookingStatus.approved => '',
  };
}

class _DeadlineCard extends StatelessWidget {
  const _DeadlineCard({required this.deadline});

  final DateTime deadline;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.cautionWash,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: StreamBuilder<int>(
          stream: Stream<int>.periodic(const Duration(seconds: 1), (i) => i),
          builder: (context, snapshot) {
            final remaining = deadline.difference(DateTime.now());
            final expired = remaining.isNegative;
            return Row(
              children: [
                Icon(
                  expired ? Icons.timer_off_outlined : Icons.timer_outlined,
                  color: colors.cautionInk,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    expired
                        ? 'Payment deadline passed'
                        : 'Pay within ${_format(remaining)}',
                    style: AppTextStyles.body.copyWith(
                      color: colors.cautionInk,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static String _format(Duration remaining) {
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    final seconds = remaining.inSeconds.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}m';
    if (minutes > 0) return '${minutes}m ${seconds}s';
    return '${seconds}s';
  }
}

class _PayButton extends StatelessWidget {
  const _PayButton({
    required this.deadline,
    required this.isProcessing,
    required this.label,
    required this.onPressed,
  });

  final DateTime? deadline;
  final bool isProcessing;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final value = deadline;
    if (value == null) {
      return PrimaryButton(
        label: 'Pay $label',
        isLoading: isProcessing,
        onPressed: onPressed,
      );
    }
    return StreamBuilder<int>(
      stream: Stream<int>.periodic(const Duration(seconds: 1), (i) => i),
      builder: (context, snapshot) {
        final expired = !value.isAfter(DateTime.now());
        return PrimaryButton(
          label: expired ? 'Payment deadline passed' : 'Pay $label',
          isLoading: isProcessing,
          onPressed: expired ? null : onPressed,
        );
      },
    );
  }
}
