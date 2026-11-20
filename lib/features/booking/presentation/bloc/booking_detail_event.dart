part of 'booking_detail_bloc.dart';

sealed class BookingDetailEvent extends Equatable {
  const BookingDetailEvent();

  @override
  List<Object?> get props => [];
}

final class BookingDetailStarted extends BookingDetailEvent {
  const BookingDetailStarted();
}

final class BookingDetailCancelRequested extends BookingDetailEvent {
  const BookingDetailCancelRequested({this.reason});

  final String? reason;

  @override
  List<Object?> get props => [reason];
}

final class BookingDetailAgreementAcknowledged extends BookingDetailEvent {
  const BookingDetailAgreementAcknowledged();
}

final class BookingDetailActionAcknowledged extends BookingDetailEvent {
  const BookingDetailActionAcknowledged();
}

final class _BookingChanged extends BookingDetailEvent {
  const _BookingChanged(this.result);

  final Result<BookingView> result;

  @override
  List<Object?> get props => [result];
}
