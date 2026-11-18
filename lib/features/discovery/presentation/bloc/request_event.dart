part of 'request_bloc.dart';

sealed class RequestEvent {
  const RequestEvent();
}

final class RequestTermsChanged extends RequestEvent {
  const RequestTermsChanged(this.accepted);

  final bool accepted;
}

final class RequestSubmitted extends RequestEvent {
  const RequestSubmitted();
}
