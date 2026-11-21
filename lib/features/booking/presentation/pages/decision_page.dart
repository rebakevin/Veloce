import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:veloce/core/formatting/formatters.dart';
import 'package:veloce/core/layout/responsive.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/validation/validators.dart';
import 'package:veloce/core/widgets/app_messenger.dart';
import 'package:veloce/core/widgets/app_text_field.dart';
import 'package:veloce/core/widgets/dialog_buttons.dart';
import 'package:veloce/core/widgets/error_view.dart';
import 'package:veloce/core/widgets/loading_view.dart';
import 'package:veloce/core/widgets/page_app_bar.dart';
import 'package:veloce/core/widgets/primary_button.dart';
import 'package:veloce/core/widgets/rating_stars.dart';
import 'package:veloce/core/widgets/status_chip.dart';
import 'package:veloce/core/widgets/user_avatar.dart';

import '../bloc/decision_bloc.dart';
import '../widgets/booking_card.dart';
import '../widgets/booking_price_breakdown.dart';

/// Owner request detail `/booking/:id/decision`.
class DecisionPage extends StatelessWidget {
  const DecisionPage({required this.bookingId, super.key});

  final String bookingId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DecisionBloc>(
      create: (_) =>
          GetIt.instance<DecisionBloc>(param1: bookingId)
            ..add(const DecisionStarted()),
      child: DecisionView(bookingId: bookingId),
    );
  }
}

class DecisionView extends StatelessWidget {
  const DecisionView({required this.bookingId, super.key});

  final String bookingId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PageAppBar(title: 'Request'),
      body: BlocConsumer<DecisionBloc, DecisionState>(
        listenWhen: (previous, current) {
          if (current is! DecisionLoaded) return false;
          if (!_finished(current.action.status)) return false;
          return previous is! DecisionLoaded ||
              previous.action != current.action;
        },
        listener: (context, state) {
          if (state is! DecisionLoaded) return;
          final action = state.action;
          final messenger = GetIt.instance<AppMessenger>();
          if (action.status == DecisionActionStatus.success) {
            messenger.success(
              action.kind == DecisionActionKind.approve
                  ? 'Request approved.'
                  : 'Request declined.',
            );
            context.read<DecisionBloc>().add(
              const DecisionActionAcknowledged(),
            );
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RouteNames.ownerActivity);
            }
          } else {
            messenger.error(action.message ?? 'Something went wrong.');
            context.read<DecisionBloc>().add(
              const DecisionActionAcknowledged(),
            );
          }
        },
        builder: (context, state) => switch (state) {
          DecisionLoading() => const LoadingView(),
          DecisionFailure(:final failure) => ErrorView(
            message: failure.message,
            onRetry: () =>
                context.read<DecisionBloc>().add(const DecisionStarted()),
          ),
          DecisionLoaded() => _DecisionBody(state: state),
        },
      ),
    );
  }

  static bool _finished(DecisionActionStatus status) =>
      status == DecisionActionStatus.success ||
      status == DecisionActionStatus.failure;
}

class _DecisionBody extends StatelessWidget {
  const _DecisionBody({required this.state});

  final DecisionLoaded state;

  @override
  Widget build(BuildContext context) {
    final view = state.view;
    final booking = view.booking;
    final renter = view.renter;
    final action = state.action;
    final colors = context.colors;
    return ListView(
      padding: Responsive.pagePadding(context).copyWith(
        top: AppSpacing.lg,
        bottom: AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        BookingCard(
          child: Column(
            children: [
              UserAvatar(
                name: renter.name,
                photoUrl: renter.photoUrl,
                radius: 40,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                renter.name,
                textAlign: TextAlign.center,
                style: AppTextStyles.title.copyWith(color: colors.ink),
              ),
              const SizedBox(height: AppSpacing.sm),
              RatingStars(rating: renter.ratingAvg, count: renter.ratingCount),
              const SizedBox(height: AppSpacing.sm),
              Text(
                renter.completedCount == 1
                    ? '1 past rental'
                    : '${renter.completedCount} past rentals',
                style: AppTextStyles.bodySmall.copyWith(color: colors.muted),
              ),
              if (renter.completedCount == 0) ...[
                const SizedBox(height: AppSpacing.sm),
                const StatusChip(
                  label: 'First-time user',
                  tone: StatusTone.info,
                ),
              ],
              TextButton(
                onPressed: () => context.push(RouteNames.user(renter.id)),
                child: const Text('View full profile'),
              ),
            ],
          ),
        ),
        const SizedBox(height: _gap),
        BookingCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Request',
                style: AppTextStyles.cardTitle.copyWith(
                  color: colors.ink,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              _InfoRow(
                label: 'Car',
                value: '${view.vehicle.make} ${view.vehicle.model}',
              ),
              _InfoRow(label: 'Plate', value: view.vehicle.plate),
              _InfoRow(
                label: 'Dates',
                value: Formatters.dateRange(booking.startDate, booking.endDate),
              ),
              _InfoRow(
                label: 'Days',
                value: '${booking.days} day${booking.days == 1 ? '' : 's'}',
              ),
              const SizedBox(height: AppSpacing.sm),
              BookingPriceBreakdown(booking: booking, showOwnerView: true),
            ],
          ),
        ),
        const SizedBox(height: _gap),
        Material(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: CheckboxListTile(
            value: state.reviewed,
            onChanged: action.isSubmitting
                ? null
                : (value) => context.read<DecisionBloc>().add(
                    DecisionReviewToggled(value ?? false),
                  ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
            ),
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('I reviewed their info'),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: action.isSubmitting ? null : () => _decline(context),
                child: const Text('Decline'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: PrimaryButton(
                label: 'Approve',
                isLoading:
                    action.isSubmitting &&
                    action.kind == DecisionActionKind.approve,
                onPressed: state.reviewed && !action.isSubmitting
                    ? () => context.read<DecisionBloc>().add(
                        const DecisionApproved(),
                      )
                    : null,
              ),
            ),
          ],
        ),
        if (action.status == DecisionActionStatus.failure) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            action.message ?? 'Something went wrong.',
            style: AppTextStyles.body.copyWith(color: colors.danger),
          ),
        ],
      ],
    );
  }

  static const double _gap = 14;

  Future<void> _decline(BuildContext context) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => const _DeclineDialog(),
    );
    if (reason == null || !context.mounted) return;
    context.read<DecisionBloc>().add(DecisionDeclineSubmitted(reason));
  }
}

class _DeclineDialog extends StatefulWidget {
  const _DeclineDialog();

  @override
  State<_DeclineDialog> createState() => _DeclineDialogState();
}

class _DeclineDialogState extends State<_DeclineDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Decline this request?'),
      content: Form(
        key: _formKey,
        child: AppTextField(
          label: 'Reason',
          hint: 'Tell the renter why',
          controller: _controller,
          maxLines: 3,
          validator: (value) =>
              Validators.requiredText(value, field: 'A reason'),
        ),
      ),
      actions: [
        DialogButtons(
          confirmLabel: 'Decline',
          destructive: true,
          onCancel: () => Navigator.of(context).pop(),
          onConfirm: () {
            if (!(_formKey.currentState?.validate() ?? false)) return;
            Navigator.of(context).pop(_controller.text.trim());
          },
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
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
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTextStyles.bodySmall.copyWith(
                color: context.colors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
