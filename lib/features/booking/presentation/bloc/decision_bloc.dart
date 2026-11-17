import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';

import '../../domain/entities/booking_view.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../domain/usecases/approve_booking.dart';
import '../../domain/usecases/decline_booking.dart';

part 'decision_event.dart';
part 'decision_state.dart';

/// Owner request detail: the review tick gates approval, and a decline needs a
/// reason before it reaches the repository.
class DecisionBloc extends Bloc<DecisionEvent, DecisionState> {
  DecisionBloc({
    required this._bookingId,
    required this._repository,
    required this._approve,
    required this._decline,
    required this._session,
  }) : super(const DecisionLoading()) {
    on<DecisionStarted>(_onStarted);
    on<DecisionReviewToggled>(_onReviewed);
    on<DecisionApproved>(_onApproved);
    on<DecisionDeclineSubmitted>(_onDeclined);
    on<DecisionActionAcknowledged>(_onAcknowledged);
    on<_DecisionBookingChanged>(_onChanged);
  }

  final String _bookingId;
  final BookingRepository _repository;
  final ApproveBooking _approve;
  final DeclineBooking _decline;
  final AuthSession _session;

  Future<void> _onStarted(
    DecisionStarted event,
    Emitter<DecisionState> emit,
  ) async {
    if (_session.role != UserRole.owner) {
      emit(
        const DecisionFailure(
          PermissionFailure('Only the car owner can review requests.'),
        ),
      );
      return;
    }
    emit(const DecisionLoading());
    await emit.onEach<Result<BookingView>>(
      _repository.watchBooking(_bookingId),
      onData: (result) => add(_DecisionBookingChanged(result)),
    );
  }

  void _onChanged(_DecisionBookingChanged event, Emitter<DecisionState> emit) {
    if (_session.role != UserRole.owner) {
      emit(
        const DecisionFailure(
          PermissionFailure('Only the car owner can review requests.'),
        ),
      );
      return;
    }
    switch (event.result) {
      case Success<BookingView>(:final value):
        final current = state;
        emit(
          DecisionLoaded(
            view: value,
            reviewed: current is DecisionLoaded && current.reviewed,
            action: current is DecisionLoaded
                ? current.action
                : DecisionAction.idle,
          ),
        );
      case Failure<BookingView>(:final failure):
        emit(DecisionFailure(failure));
    }
  }

  void _onReviewed(DecisionReviewToggled event, Emitter<DecisionState> emit) {
    final current = state;
    if (current is! DecisionLoaded || current.action.isSubmitting) return;
    emit(current.copyWith(reviewed: event.reviewed));
  }

  Future<void> _onApproved(
    DecisionApproved event,
    Emitter<DecisionState> emit,
  ) async {
    final current = state;
    if (current is! DecisionLoaded || current.action.isSubmitting) return;
    emit(
      current.copyWith(
        action: const DecisionAction(
          kind: DecisionActionKind.approve,
          status: DecisionActionStatus.submitting,
        ),
      ),
    );
    final result = await _approve(_bookingId, reviewed: current.reviewed);
    if (isClosed) return;
    emit(
      current.copyWith(action: _actionFor(DecisionActionKind.approve, result)),
    );
  }

  Future<void> _onDeclined(
    DecisionDeclineSubmitted event,
    Emitter<DecisionState> emit,
  ) async {
    final current = state;
    if (current is! DecisionLoaded || current.action.isSubmitting) return;
    emit(
      current.copyWith(
        action: const DecisionAction(
          kind: DecisionActionKind.decline,
          status: DecisionActionStatus.submitting,
        ),
      ),
    );
    final result = await _decline(_bookingId, reason: event.reason);
    if (isClosed) return;
    emit(
      current.copyWith(action: _actionFor(DecisionActionKind.decline, result)),
    );
  }

  void _onAcknowledged(
    DecisionActionAcknowledged event,
    Emitter<DecisionState> emit,
  ) {
    final current = state;
    if (current is! DecisionLoaded || current.action.isSubmitting) return;
    emit(current.copyWith(action: DecisionAction.idle));
  }

  DecisionAction _actionFor(DecisionActionKind kind, Result<void> result) =>
      switch (result) {
        Success<void>() => DecisionAction(
          kind: kind,
          status: DecisionActionStatus.success,
        ),
        Failure<void>(:final failure) => DecisionAction(
          kind: kind,
          status: DecisionActionStatus.failure,
          message: failure.message,
        ),
      };
}
