import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:veloce/core/domain/entities/vehicle.dart';
import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';

import '../../domain/entities/booking_view.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../domain/usecases/cancel_booking.dart';
import '../../domain/usecases/expire_bookings.dart';

part 'activity_event.dart';
part 'activity_state.dart';

/// My Activity for either role: Open, Active and Past lists, grouped by car for
/// owners. It sweeps due expiries once when the list opens and then watches the
/// bookings stream.
class ActivityBloc extends Bloc<ActivityEvent, ActivityState> {
  ActivityBloc({
    required this._repository,
    required this._cancelBooking,
    required this._expireBookings,
    required this._session,
  }) : super(const ActivityLoading()) {
    on<ActivityStarted>(_onStarted);
    on<ActivityTabChanged>(_onTabChanged);
    on<ActivityCancelRequested>(_onCancelRequested);
    on<ActivityActionAcknowledged>(_onAcknowledged);
    on<_BookingsChanged>(_onChanged);
  }

  final BookingRepository _repository;
  final CancelBooking _cancelBooking;
  final ExpireBookings _expireBookings;
  final AuthSession _session;

  StreamSubscription<Result<List<BookingView>>>? _subscription;

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }

  Future<void> _onStarted(
    ActivityStarted event,
    Emitter<ActivityState> emit,
  ) async {
    final role = _session.role;
    if (role == null) {
      emit(
        const ActivityFailure(
          PermissionFailure('Sign in to see your bookings.'),
        ),
      );
      return;
    }
    emit(const ActivityLoading());
    await _subscription?.cancel();
    _subscription = _repository.watchMyBookings().listen(
      (result) => add(_BookingsChanged(result)),
    );
    // The sweep runs beside the list, never in front of it: a slow or failed
    // sweep must not block the list, and expiry is also applied lazily to what
    // the list shows.
    unawaited(_expireBookings());
  }

  void _onChanged(_BookingsChanged event, Emitter<ActivityState> emit) {
    final role = _session.role;
    if (role == null) {
      emit(
        const ActivityFailure(
          PermissionFailure('Sign in to see your bookings.'),
        ),
      );
      return;
    }
    switch (event.result) {
      case Success<List<BookingView>>(:final value):
        final current = state;
        emit(
          ActivityLoaded(
            role: role,
            bookings: value,
            tab: current is ActivityLoaded ? current.tab : ActivityTab.open,
            action: current is ActivityLoaded
                ? current.action
                : ActivityAction.idle,
          ),
        );
      case Failure<List<BookingView>>(:final failure):
        emit(ActivityFailure(failure));
    }
  }

  void _onTabChanged(ActivityTabChanged event, Emitter<ActivityState> emit) {
    final current = state;
    if (current is! ActivityLoaded) return;
    emit(current.copyWith(tab: event.tab));
  }

  Future<void> _onCancelRequested(
    ActivityCancelRequested event,
    Emitter<ActivityState> emit,
  ) async {
    final current = state;
    if (current is! ActivityLoaded || current.action.isSubmitting) return;

    emit(
      current.copyWith(
        action: const ActivityAction(
          kind: ActivityActionKind.cancel,
          status: ActivityActionStatus.submitting,
        ),
      ),
    );
    final result = await _cancelBooking(event.view, reason: event.reason);
    if (isClosed) return;

    // The bookings stream may have emitted while the cancel ran: build on the
    // latest state, not on the copy taken before the await.
    final latest = state;
    if (latest is! ActivityLoaded) return;
    emit(
      latest.copyWith(
        action: switch (result) {
          Success<void>() => const ActivityAction(
            kind: ActivityActionKind.cancel,
            status: ActivityActionStatus.success,
          ),
          Failure<void>(:final failure) => ActivityAction(
            kind: ActivityActionKind.cancel,
            status: ActivityActionStatus.failure,
            message: failure.message,
          ),
        },
      ),
    );
  }

  void _onAcknowledged(
    ActivityActionAcknowledged event,
    Emitter<ActivityState> emit,
  ) {
    final current = state;
    if (current is! ActivityLoaded || current.action.isSubmitting) return;
    emit(current.copyWith(action: ActivityAction.idle));
  }
}
