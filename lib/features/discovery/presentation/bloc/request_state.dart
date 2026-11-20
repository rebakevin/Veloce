part of 'request_bloc.dart';

sealed class RequestState extends Equatable {
  const RequestState();
}

final class RequestEditing extends RequestState {
  const RequestEditing({
    required this.draft,
    this.termsAccepted = false,
    this.isSubmitting = false,
    this.failureMessage,
  });

  final BookingRequestDraft draft;
  final bool termsAccepted;
  final bool isSubmitting;
  final String? failureMessage;

  RequestEditing copyWith({
    bool? termsAccepted,
    bool? isSubmitting,
    String? failureMessage,
    bool clearFailure = false,
  }) {
    return RequestEditing(
      draft: draft,
      termsAccepted: termsAccepted ?? this.termsAccepted,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      failureMessage: clearFailure
          ? null
          : (failureMessage ?? this.failureMessage),
    );
  }

  @override
  List<Object?> get props => [
    draft,
    termsAccepted,
    isSubmitting,
    failureMessage,
  ];
}

final class RequestSuccess extends RequestState {
  const RequestSuccess(this.booking);

  final Booking booking;

  @override
  List<Object?> get props => [booking];
}
