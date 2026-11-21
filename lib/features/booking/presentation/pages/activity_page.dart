import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/layout/responsive.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/app_messenger.dart';
import 'package:veloce/core/widgets/empty_state.dart';
import 'package:veloce/core/widgets/error_view.dart';
import 'package:veloce/core/widgets/loading_view.dart';
import 'package:veloce/core/widgets/page_app_bar.dart';

import '../../domain/entities/booking_view.dart';
import '../bloc/activity_bloc.dart';
import '../widgets/booking_list_card.dart';
import '../widgets/cancel_booking_dialog.dart';

/// My Activity tab for both roles. When [vehicleId] is set it shows only that
/// car's open requests, which is the per-car requests screen.
class ActivityPage extends StatelessWidget {
  const ActivityPage({
    super.key,
    this.vehicleId,
    this.title = 'My activity',
    this.standalone = false,
  });

  final String? vehicleId;
  final String title;
  final bool standalone;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ActivityBloc>(
      create: (_) =>
          GetIt.instance<ActivityBloc>()..add(const ActivityStarted()),
      child: ActivityView(
        vehicleId: vehicleId,
        title: title,
        standalone: standalone,
      ),
    );
  }
}

class ActivityView extends StatelessWidget {
  const ActivityView({
    super.key,
    this.vehicleId,
    this.title = 'My activity',
    this.standalone = false,
  });

  final String? vehicleId;
  final String title;
  final bool standalone;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: standalone
          ? PageAppBar(title: title)
          : AppBar(title: Text(title)),
      body: BlocConsumer<ActivityBloc, ActivityState>(
        listenWhen: (previous, current) {
          if (current is! ActivityLoaded) return false;
          if (!_isFinished(current.action.status)) return false;
          return previous is! ActivityLoaded ||
              previous.action != current.action;
        },
        listener: (context, state) {
          if (state is! ActivityLoaded) return;
          final action = state.action;
          final messenger = GetIt.instance<AppMessenger>();
          if (action.status == ActivityActionStatus.success) {
            messenger.success('Booking cancelled.');
          } else {
            messenger.error(action.message ?? 'Something went wrong.');
          }
          context.read<ActivityBloc>().add(const ActivityActionAcknowledged());
        },
        builder: (context, state) => switch (state) {
          ActivityLoading() => const LoadingView(),
          ActivityFailure(:final failure) => ErrorView(
            message: failure.message,
            onRetry: () =>
                context.read<ActivityBloc>().add(const ActivityStarted()),
          ),
          ActivityLoaded() => _ActivityBody(state: state, vehicleId: vehicleId),
        },
      ),
    );
  }

  static bool _isFinished(ActivityActionStatus status) =>
      status == ActivityActionStatus.success ||
      status == ActivityActionStatus.failure;
}

class _ActivityBody extends StatelessWidget {
  const _ActivityBody({required this.state, this.vehicleId});

  final ActivityLoaded state;
  final String? vehicleId;

  @override
  Widget build(BuildContext context) {
    final filteredVehicle = vehicleId;
    final visible = filteredVehicle == null
        ? state.visible
        : state.visible
              .where((view) => view.vehicle.id == filteredVehicle)
              .toList();
    final groups = filteredVehicle == null
        ? state.openGroups
        : state.openGroups
              .where((group) => group.vehicle.id == filteredVehicle)
              .toList();

    return ListView(
      padding: Responsive.pagePadding(context)
          .copyWith(top: AppSpacing.lg, bottom: AppSpacing.xl),
      children: [
        if (filteredVehicle == null) ...[
          _ActivityTabs(state: state),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (state.role == UserRole.owner &&
            state.tab == ActivityTab.open &&
            filteredVehicle == null) ...[
          if (groups.isEmpty)
            _empty(context, ActivityTab.open)
          else
            for (final group in groups)
              _OwnerGroup(
                group: group,
                onOpen: (view) => _openBooking(context, view),
              ),
        ] else if (visible.isEmpty)
          _empty(context, state.tab)
        else
          for (final view in visible) ...[
            BookingListCard(
              view: view,
              role: state.role,
              onTap: () => _openBooking(context, view),
              actions: _actions(context, view),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
      ],
    );
  }

  List<Widget> _actions(BuildContext context, BookingView view) {
    final role = state.role;
    final id = view.booking.id;
    final actions = <Widget>[];
    if (role == UserRole.renter) {
      switch (view.effectiveStatus) {
        case BookingStatus.pending:
          actions.add(
            _actionButton(
              'Cancel request',
              () => _cancel(context, view),
              destructive: true,
            ),
          );
        case BookingStatus.approved:
          actions
            ..add(
              _actionButton(
                'Pay now',
                () => context.push(RouteNames.bookingPay(id)),
              ),
            )
            ..add(
              _actionButton(
                'Cancel',
                () => _cancel(context, view),
                destructive: true,
              ),
            );
        case BookingStatus.confirmed:
          actions.add(
            _actionButton(
              'Cancel booking',
              () => _cancel(context, view),
              destructive: true,
            ),
          );
        case _:
          break;
      }
    } else {
      switch (view.effectiveStatus) {
        case BookingStatus.pending:
          actions.add(
            _actionButton(
              'Review request',
              () => context.push(RouteNames.bookingDecision(id)),
            ),
          );
        case BookingStatus.approved || BookingStatus.confirmed:
          actions.add(
            _actionButton(
              'Cancel booking',
              () => _cancel(context, view),
              destructive: true,
            ),
          );
        case _:
          break;
      }
    }
    return actions;
  }

  Widget _actionButton(
    String label,
    VoidCallback onPressed, {
    bool destructive = false,
  }) {
    final style = const ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(0, 40)),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      ),
    );
    return destructive
        ? OutlinedButton(style: style, onPressed: onPressed, child: Text(label))
        : FilledButton(style: style, onPressed: onPressed, child: Text(label));
  }

  Future<void> _cancel(BuildContext context, BookingView view) async {
    final bloc = context.read<ActivityBloc>();
    final confirmed = await showCancelBookingDialog(context, view);
    if (!confirmed || !context.mounted) return;
    bloc.add(ActivityCancelRequested(view));
  }

  void _openBooking(BuildContext context, BookingView view) {
    context.push(RouteNames.booking(view.booking.id));
  }

  Widget _empty(BuildContext context, ActivityTab tab) {
    final (title, message) = switch (tab) {
      ActivityTab.open => (
        'Nothing needs your attention',
        'Open requests and approved bookings appear here.',
      ),
      ActivityTab.active => (
        'No active rentals',
        'Confirmed and ongoing rentals appear here.',
      ),
      ActivityTab.past => (
        'No past bookings',
        'Completed, declined, expired and cancelled bookings appear here.',
      ),
    };
    return EmptyState(title: title, message: message);
  }
}

class _OwnerGroup extends StatelessWidget {
  const _OwnerGroup({required this.group, required this.onOpen});

  final ActivityGroup group;
  final ValueChanged<BookingView> onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${group.vehicle.make} ${group.vehicle.model} · ${group.vehicle.plate}',
                style: AppTextStyles.cardTitle,
              ),
            ),
            Text(
              '${group.bookings.length} open',
              style: AppTextStyles.caption.copyWith(color: colors.muted),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final view in group.bookings) ...[
          BookingListCard(
            view: view,
            role: UserRole.owner,
            onTap: () => onOpen(view),
            actions: [
              if (view.effectiveStatus == BookingStatus.pending)
                FilledButton(
                  style: const ButtonStyle(
                    minimumSize: WidgetStatePropertyAll(Size(0, 40)),
                    padding: WidgetStatePropertyAll(
                      EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    ),
                  ),
                  onPressed: () =>
                      context.push(RouteNames.bookingDecision(view.booking.id)),
                  child: const Text('Review request'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}

class _ActivityTabs extends StatelessWidget {
  const _ActivityTabs({required this.state});

  final ActivityLoaded state;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (ActivityTab.open, 'Open', state.open.length),
      (ActivityTab.active, 'Active', state.active.length),
      (ActivityTab.past, 'Past', state.past.length),
    ];
    return Row(
      children: [
        for (var index = 0; index < tabs.length; index++) ...[
          if (index > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _TabButton(
              label: '${tabs[index].$2} ${tabs[index].$3}',
              selected: state.tab == tabs[index].$1,
              onPressed: () => context.read<ActivityBloc>().add(
                ActivityTabChanged(tabs[index].$1),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return selected
        ? FilledButton(onPressed: onPressed, child: Text(label))
        : OutlinedButton(onPressed: onPressed, child: Text(label));
  }
}
