import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:veloce/core/domain/entities/booking_contact.dart';
import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';

import '../../domain/entities/booking_view.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../domain/usecases/acknowledge_agreement.dart';
import '../../domain/usecases/cancel_booking.dart';

part 'booking_detail_event.dart';
part 'booking_detail_state.dart';

/// Watches one booking and loads the other party's contact only when the
/// booking is paid.
class BookingDetailBloc extends Bloc<BookingDetailEvent, BookingDetailState> {
  BookingDetailBloc({
    required this._bookingId,
    required this._repository,
    required this._cancelBooking,
    required this._acknowledgeAgreement,
    required this._session,
  }) : super(const BookingDetailLoading()) {
    on<BookingDetailStarted>(_onStarted);
    on<BookingDetailCancelRequested>(_onCancel);
    on<BookingDetailAgreementAcknowledged>(_onAcknowledge);
    on<BookingDetailActionAcknowledged>(_onAcknowledged);
    on<_BookingChanged>(_onChanged);
  }

  final String _bookingId;
  final BookingRepository _repository;
  final CancelBooking _cancelBooking;
  final AcknowledgeAgreement _acknowledgeAgreement;
  final AuthSession _session;

  Future<void> _onStarted(
    BookingDetailStarted event,
    Emitter<BookingDetailState> emit,
  ) async {
    final role = _session.role;
    if (role == null) {
      emit(
        const BookingDetailFailure(
          PermissionFailure('Sign in to see this booking.'),
        ),
      );
      return;
    }
    emit(const BookingDetailLoading());
    await emit.onEach<Result<BookingView>>(
      _repository.watchBooking(_bookingId),
      onData: (result) => add(_BookingChanged(result)),
    );
  }

  Future<void> _onChanged(
    _BookingChanged event,
    Emitter<BookingDetailState> emit,
  ) async {
    final role = _session.role;
    if (role == null) {
      emit(
        const BookingDetailFailure(
          PermissionFailure('Sign in to see this booking.'),
        ),
      );
      return;
    }
    switch (event.result) {
      case Success<BookingView>(:final value):
        BookingContact? contact;
        AppFailure? contactFailure;
        if (value.isContactUnlocked) {
          final loaded = await _repository.getCounterpartyContact(_bookingId);
          if (isClosed) return;
          switch (loaded) {
            case Success<BookingContact?>(:final value):
              contact = value;
            case Failure<BookingContact?>(:final failure):
              contactFailure = failure;
          }
        }
        if (isClosed) return;
        final current = state;
        final action = current is BookingDetailLoaded
            ? current.action
            : BookingDetailAction.idle;
        emit(
          BookingDetailLoaded(
            view: value,
            role: role,
            contact: contact,
            action: contactFailure == null
                ? action
                : BookingDetailAction(
                    kind: BookingDetailActionKind.contact,
                    status: BookingDetailActionStatus.failure,
                    message: contactFailure.message,
                  ),
          ),
        );
      case Failure<BookingView>(:final failure):
        emit(BookingDetailFailure(failure));
    }
  }

  Future<void> _onCancel(
    BookingDetailCancelRequested event,
    Emitter<BookingDetailState> emit,
  ) async {
    final current = state;
    if (current is! BookingDetailLoaded || current.action.isSubmitting) return;
    emit(
      current.copyWith(
        action: const BookingDetailAction(
          kind: BookingDetailActionKind.cancel,
          status: BookingDetailActionStatus.submitting,
        ),
      ),
    );
    final result = await _cancelBooking(current.view, reason: event.reason);
    if (isClosed) return;
    emit(
      current.copyWith(
        action: switch (result) {
          Success<void>() => const BookingDetailAction(
            kind: BookingDetailActionKind.cancel,
            status: BookingDetailActionStatus.success,
          ),
          Failure<void>(:final failure) => BookingDetailAction(
            kind: BookingDetailActionKind.cancel,
            status: BookingDetailActionStatus.failure,
            message: failure.message,
          ),
        },
      ),
    );
  }

  Future<void> _onAcknowledge(
    BookingDetailAgreementAcknowledged event,
    Emitter<BookingDetailState> emit,
  ) async {
    final current = state;
    if (current is! BookingDetailLoaded || current.action.isSubmitting) return;
    emit(
      current.copyWith(
        action: const BookingDetailAction(
          kind: BookingDetailActionKind.agreement,
          status: BookingDetailActionStatus.submitting,
        ),
      ),
    );
    final result = await _acknowledgeAgreement(_bookingId);
    if (isClosed) return;
    emit(
      current.copyWith(
        action: switch (result) {
          Success<void>() => const BookingDetailAction(
            kind: BookingDetailActionKind.agreement,
            status: BookingDetailActionStatus.success,
          ),
          Failure<void>(:final failure) => BookingDetailAction(
            kind: BookingDetailActionKind.agreement,
            status: BookingDetailActionStatus.failure,
            message: failure.message,
          ),
        },
      ),
    );
  }

  void _onAcknowledged(
    BookingDetailActionAcknowledged event,
    Emitter<BookingDetailState> emit,
  ) {
    final current = state;
    if (current is! BookingDetailLoaded || current.action.isSubmitting) return;
    emit(current.copyWith(action: BookingDetailAction.idle));
  }
}
