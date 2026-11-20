part of 'payment_bloc.dart';

sealed class PaymentEvent extends Equatable {
  const PaymentEvent();

  @override
  List<Object?> get props => [];
}

final class PaymentStarted extends PaymentEvent {
  const PaymentStarted();
}

/// [momoNumber] is the 9 digits after the leading 0.
final class PaymentSubmitted extends PaymentEvent {
  const PaymentSubmitted(this.momoNumber);

  final String momoNumber;

  @override
  List<Object?> get props => [momoNumber];
}

final class PaymentRetried extends PaymentEvent {
  const PaymentRetried();
}

final class PaymentActionAcknowledged extends PaymentEvent {
  const PaymentActionAcknowledged();
}

final class _PaymentBookingChanged extends PaymentEvent {
  const _PaymentBookingChanged(this.result);

  final Result<BookingView> result;

  @override
  List<Object?> get props => [result];
}
