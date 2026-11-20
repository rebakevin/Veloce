part of 'car_detail_bloc.dart';

sealed class CarDetailEvent {
  const CarDetailEvent();
}

final class CarDetailStarted extends CarDetailEvent {
  const CarDetailStarted();
}

final class CarDetailRetried extends CarDetailEvent {
  const CarDetailRetried();
}

final class CarDetailDatesChanged extends CarDetailEvent {
  const CarDetailDatesChanged(this.start, this.end);

  final DateTime start;
  final DateTime end;
}

final class CarDetailTermsChanged extends CarDetailEvent {
  const CarDetailTermsChanged(this.accepted);

  final bool accepted;
}
