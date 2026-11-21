import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/domain/services/momo_gateway.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';

import '../../domain/entities/booking_view.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../domain/usecases/pay_booking.dart';

part 'payment_event.dart';
part 'payment_state.dart';

/// Renter payment. A failed charge leaves the booking approved and keeps the
/// last MoMo number so Retry can send the same payment again.
class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  PaymentBloc({
    required this._bookingId,
    required this._repository,
    required this._pay,
    required this._session,
  }) : super(const PaymentLoading()) {
    on<PaymentStarted>(_onStarted);
    on<PaymentSubmitted>(_onSubmitted);
    on<PaymentRetried>(_onRetried);
    on<PaymentActionAcknowledged>(_onAcknowledged);
    on<_PaymentBookingChanged>(_onChanged);
  }

  final String _bookingId;
  final BookingRepository _repository;
  final PayBooking _pay;
  final AuthSession _session;

  String? _lastMomoNumber;
  StreamSubscription<Result<BookingView>>? _subscription;

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }

  Future<void> _onStarted(
    PaymentStarted event,
    Emitter<PaymentState> emit,
  ) async {
    if (_session.role != UserRole.renter) {
      emit(
        const PaymentFailure(
          PermissionFailure('Only the renter can pay for this booking.'),
        ),
      );
      return;
    }
    emit(const PaymentLoading());
    await _subscription?.cancel();
    _subscription = _repository
        .watchBooking(_bookingId)
        .listen((result) => add(_PaymentBookingChanged(result)));
  }

  void _onChanged(_PaymentBookingChanged event, Emitter<PaymentState> emit) {
    if (_session.role != UserRole.renter) {
      emit(
        const PaymentFailure(
          PermissionFailure('Only the renter can pay for this booking.'),
        ),
      );
      return;
    }
    switch (event.result) {
      case Success<BookingView>(:final value):
        final current = state;
        emit(
          PaymentLoaded(
            view: value,
            action: current is PaymentLoaded
                ? current.action
                : PaymentAction.idle,
          ),
        );
      case Failure<BookingView>(:final failure):
        emit(PaymentFailure(failure));
    }
  }

  Future<void> _onSubmitted(
    PaymentSubmitted event,
    Emitter<PaymentState> emit,
  ) => _charge(event.momoNumber, emit);

  Future<void> _onRetried(PaymentRetried event, Emitter<PaymentState> emit) {
    final number = _lastMomoNumber;
    if (number == null) return Future.value();
    return _charge(number, emit);
  }

  Future<void> _charge(String momoNumber, Emitter<PaymentState> emit) async {
    final current = state;
    if (current is! PaymentLoaded || current.action.isProcessing) return;
    _lastMomoNumber = momoNumber;
    emit(
      current.copyWith(
        action: const PaymentAction(status: PaymentActionStatus.processing),
      ),
    );
    final result = await _pay(current.view, momoNumber: momoNumber);
    if (isClosed) return;
    final latest = state;
    if (latest is! PaymentLoaded) return;
    emit(
      latest.copyWith(
        action: switch (result) {
          Success<MomoReceipt>(:final value) => PaymentAction(
            status: PaymentActionStatus.success,
            reference: value.reference,
          ),
          Failure<MomoReceipt>(:final failure) => PaymentAction(
            status: PaymentActionStatus.failure,
            message: failure.message,
          ),
        },
      ),
    );
  }

  void _onAcknowledged(
    PaymentActionAcknowledged event,
    Emitter<PaymentState> emit,
  ) {
    final current = state;
    if (current is! PaymentLoaded || current.action.isProcessing) return;
    emit(current.copyWith(action: PaymentAction.idle));
  }
}
