part of 'activity_bloc.dart';

enum ActivityTab { open, active, past }

enum ActivityActionKind { cancel }

enum ActivityActionStatus { idle, submitting, success, failure }

class ActivityAction extends Equatable {
  const ActivityAction({
    this.kind,
    this.status = ActivityActionStatus.idle,
    this.message,
  });

  static const ActivityAction idle = ActivityAction();

  final ActivityActionKind? kind;
  final ActivityActionStatus status;
  final String? message;

  bool get isSubmitting => status == ActivityActionStatus.submitting;

  @override
  List<Object?> get props => [kind, status, message];
}

class ActivityGroup extends Equatable {
  const ActivityGroup({required this.vehicle, required this.bookings});

  final Vehicle vehicle;
  final List<BookingView> bookings;

  @override
  List<Object?> get props => [vehicle, bookings];
}

sealed class ActivityState extends Equatable {
  const ActivityState();

  @override
  List<Object?> get props => [];
}

final class ActivityLoading extends ActivityState {
  const ActivityLoading();
}

final class ActivityFailure extends ActivityState {
  const ActivityFailure(this.failure);

  final AppFailure failure;

  @override
  List<Object?> get props => [failure];
}

final class ActivityLoaded extends ActivityState {
  const ActivityLoaded({
    required this.role,
    required this.bookings,
    this.tab = ActivityTab.open,
    this.action = ActivityAction.idle,
  });

  final UserRole role;
  final List<BookingView> bookings;
  final ActivityTab tab;
  final ActivityAction action;

  List<BookingView> get open =>
      _sorted(bookings.where((view) => view.isOpen), ascending: true);

  List<BookingView> get active =>
      _sorted(bookings.where((view) => view.isActive), ascending: true);

  List<BookingView> get past =>
      _sorted(bookings.where((view) => view.isPast), ascending: false);

  List<BookingView> get visible => switch (tab) {
    ActivityTab.open => open,
    ActivityTab.active => active,
    ActivityTab.past => past,
  };

  /// Owners see pending and approved requests under one heading per car.
  List<ActivityGroup> get openGroups {
    if (role != UserRole.owner) return const [];
    final byVehicle = <String, List<BookingView>>{};
    final vehicles = <String, Vehicle>{};
    for (final view in open) {
      byVehicle.putIfAbsent(view.vehicle.id, () => []).add(view);
      vehicles[view.vehicle.id] = view.vehicle;
    }
    final groups = byVehicle.entries
        .map(
          (entry) => ActivityGroup(
            vehicle: vehicles[entry.key]!,
            bookings: entry.value,
          ),
        )
        .toList();
    groups.sort(
      (a, b) => '${a.vehicle.make} ${a.vehicle.model}'.compareTo(
        '${b.vehicle.make} ${b.vehicle.model}',
      ),
    );
    return groups;
  }

  ActivityLoaded copyWith({
    List<BookingView>? bookings,
    ActivityTab? tab,
    ActivityAction? action,
  }) => ActivityLoaded(
    role: role,
    bookings: bookings ?? this.bookings,
    tab: tab ?? this.tab,
    action: action ?? this.action,
  );

  static List<BookingView> _sorted(
    Iterable<BookingView> views, {
    required bool ascending,
  }) {
    final result = views.toList();
    result.sort(
      (a, b) => ascending
          ? a.booking.startDate.compareTo(b.booking.startDate)
          : b.booking.startDate.compareTo(a.booking.startDate),
    );
    return result;
  }

  @override
  List<Object?> get props => [role, bookings, tab, action];
}
