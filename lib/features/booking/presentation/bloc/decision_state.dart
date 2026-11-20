part of 'decision_bloc.dart';

enum DecisionActionKind { approve, decline }

enum DecisionActionStatus { idle, submitting, success, failure }

class DecisionAction extends Equatable {
  const DecisionAction({
    this.kind,
    this.status = DecisionActionStatus.idle,
    this.message,
  });

  static const DecisionAction idle = DecisionAction();

  final DecisionActionKind? kind;
  final DecisionActionStatus status;
  final String? message;

  bool get isSubmitting => status == DecisionActionStatus.submitting;

  @override
  List<Object?> get props => [kind, status, message];
}

sealed class DecisionState extends Equatable {
  const DecisionState();

  @override
  List<Object?> get props => [];
}

final class DecisionLoading extends DecisionState {
  const DecisionLoading();
}

final class DecisionFailure extends DecisionState {
  const DecisionFailure(this.failure);

  final AppFailure failure;

  @override
  List<Object?> get props => [failure];
}

final class DecisionLoaded extends DecisionState {
  const DecisionLoaded({
    required this.view,
    this.reviewed = false,
    this.action = DecisionAction.idle,
  });

  final BookingView view;
  final bool reviewed;
  final DecisionAction action;

  DecisionLoaded copyWith({
    BookingView? view,
    bool? reviewed,
    DecisionAction? action,
  }) => DecisionLoaded(
    view: view ?? this.view,
    reviewed: reviewed ?? this.reviewed,
    action: action ?? this.action,
  );

  @override
  List<Object?> get props => [view, reviewed, action];
}
