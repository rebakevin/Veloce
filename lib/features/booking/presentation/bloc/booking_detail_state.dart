part of 'booking_detail_bloc.dart';

enum BookingDetailActionKind { contact, cancel, agreement }

enum BookingDetailActionStatus { idle, submitting, success, failure }

class BookingDetailAction extends Equatable {
  const BookingDetailAction({
    this.kind,
    this.status = BookingDetailActionStatus.idle,
    this.message,
  });

  static const BookingDetailAction idle = BookingDetailAction();

  final BookingDetailActionKind? kind;
  final BookingDetailActionStatus status;
  final String? message;

  bool get isSubmitting => status == BookingDetailActionStatus.submitting;

  @override
  List<Object?> get props => [kind, status, message];
}

sealed class BookingDetailState extends Equatable {
  const BookingDetailState();

  @override
  List<Object?> get props => [];
}

final class BookingDetailLoading extends BookingDetailState {
  const BookingDetailLoading();
}

final class BookingDetailFailure extends BookingDetailState {
  const BookingDetailFailure(this.failure);

  final AppFailure failure;

  @override
  List<Object?> get props => [failure];
}

final class BookingDetailLoaded extends BookingDetailState {
  const BookingDetailLoaded({
    required this.view,
    required this.role,
    this.contact,
    this.action = BookingDetailAction.idle,
  });

  final BookingView view;
  final UserRole role;

  /// `null` while the booking is not paid, or when the other side has no
  /// contact document.
  final BookingContact? contact;
  final BookingDetailAction action;

  BookingDetailLoaded copyWith({
    BookingView? view,
    BookingContact? contact,
    BookingDetailAction? action,
  }) => BookingDetailLoaded(
    view: view ?? this.view,
    role: role,
    contact: contact ?? this.contact,
    action: action ?? this.action,
  );

  @override
  List<Object?> get props => [view, role, contact, action];
}
