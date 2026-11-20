import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:veloce/core/domain/entities/booking.dart';
import 'package:veloce/core/domain/services/auth_session.dart';

import '../../domain/entities/booking_request_draft.dart';
import '../../domain/usecases/create_booking_request.dart';

part 'request_event.dart';
part 'request_state.dart';

/// Owns the review screen's terms and submission.
class RequestBloc extends Bloc<RequestEvent, RequestState> {
  RequestBloc({
    required this._createRequest,
    required this._session,
    required BookingRequestDraft draft,
  }) : super(RequestEditing(draft: draft)) {
    on<RequestTermsChanged>(_onTermsChanged);
    on<RequestSubmitted>(_onSubmitted);
  }

  final CreateBookingRequest _createRequest;
  final AuthSession _session;

  void _onTermsChanged(RequestTermsChanged event, Emitter<RequestState> emit) {
    final state = this.state;
    if (state is! RequestEditing || state.isSubmitting) return;
    emit(state.copyWith(termsAccepted: event.accepted, clearFailure: true));
  }

  Future<void> _onSubmitted(
    RequestSubmitted event,
    Emitter<RequestState> emit,
  ) async {
    final state = this.state;
    if (state is! RequestEditing || state.isSubmitting) return;
    if (!state.termsAccepted) {
      emit(
        state.copyWith(
          failureMessage: 'Tick the terms before sending the request.',
        ),
      );
      return;
    }
    final renterId = _session.currentUserId;
    if (renterId == null) {
      emit(state.copyWith(failureMessage: 'Sign in to request a car.'));
      return;
    }
    emit(state.copyWith(isSubmitting: true, clearFailure: true));
    final result = await _createRequest(
      renterId: renterId,
      vehicleId: state.draft.vehicle.id,
      start: state.draft.start,
      end: state.draft.end,
    );
    if (isClosed) return;
    result.when(
      success: (booking) => emit(RequestSuccess(booking)),
      failure: (failure) => emit(
        state.copyWith(isSubmitting: false, failureMessage: failure.message),
      ),
    );
  }
}
