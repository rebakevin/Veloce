part of 'payment_bloc.dart';

enum PaymentActionStatus { idle, processing, success, failure }

class PaymentAction extends Equatable {
  const PaymentAction({
    this.status = PaymentActionStatus.idle,
    this.message,
    this.reference,
  });

  static const PaymentAction idle = PaymentAction();

  final PaymentActionStatus status;
  final String? message;
  final String? reference;

  bool get isProcessing => status == PaymentActionStatus.processing;

  @override
  List<Object?> get props => [status, message, reference];
}

sealed class PaymentState extends Equatable {
  const PaymentState();

  @override
  List<Object?> get props => [];
}

final class PaymentLoading extends PaymentState {
  const PaymentLoading();
}

final class PaymentFailure extends PaymentState {
  const PaymentFailure(this.failure);

  final AppFailure failure;

  @override
  List<Object?> get props => [failure];
}

final class PaymentLoaded extends PaymentState {
  const PaymentLoaded({required this.view, this.action = PaymentAction.idle});

  final BookingView view;
  final PaymentAction action;

  PaymentLoaded copyWith({BookingView? view, PaymentAction? action}) =>
      PaymentLoaded(view: view ?? this.view, action: action ?? this.action);

  @override
  List<Object?> get props => [view, action];
}
