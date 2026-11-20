part of 'decision_bloc.dart';

sealed class DecisionEvent extends Equatable {
  const DecisionEvent();

  @override
  List<Object?> get props => [];
}

final class DecisionStarted extends DecisionEvent {
  const DecisionStarted();
}

final class DecisionReviewToggled extends DecisionEvent {
  const DecisionReviewToggled(this.reviewed);

  final bool reviewed;

  @override
  List<Object?> get props => [reviewed];
}

final class DecisionApproved extends DecisionEvent {
  const DecisionApproved();
}

final class DecisionDeclineSubmitted extends DecisionEvent {
  const DecisionDeclineSubmitted(this.reason);

  final String reason;

  @override
  List<Object?> get props => [reason];
}

final class DecisionActionAcknowledged extends DecisionEvent {
  const DecisionActionAcknowledged();
}

final class _DecisionBookingChanged extends DecisionEvent {
  const _DecisionBookingChanged(this.result);

  final Result<BookingView> result;

  @override
  List<Object?> get props => [result];
}
