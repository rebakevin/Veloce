part of 'activity_bloc.dart';

sealed class ActivityEvent extends Equatable {
  const ActivityEvent();

  @override
  List<Object?> get props => [];
}

/// Loads the list and starts watching it. Dispatch once, or again after a
/// [ActivityFailure].
final class ActivityStarted extends ActivityEvent {
  const ActivityStarted();
}

final class ActivityTabChanged extends ActivityEvent {
  const ActivityTabChanged(this.tab);

  final ActivityTab tab;

  @override
  List<Object?> get props => [tab];
}

final class ActivityCancelRequested extends ActivityEvent {
  const ActivityCancelRequested(this.view, {this.reason});

  final BookingView view;
  final String? reason;

  @override
  List<Object?> get props => [view, reason];
}

/// Clears the latest action result after the screen has reacted.
final class ActivityActionAcknowledged extends ActivityEvent {
  const ActivityActionAcknowledged();
}

final class _BookingsChanged extends ActivityEvent {
  const _BookingsChanged(this.result);

  final Result<List<BookingView>> result;

  @override
  List<Object?> get props => [result];
}
