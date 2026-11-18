part of 'car_detail_bloc.dart';

sealed class CarDetailState extends Equatable {
  const CarDetailState();

  @override
  List<Object?> get props => const [];
}

final class CarDetailLoading extends CarDetailState {
  const CarDetailLoading();
}

final class CarDetailFailure extends CarDetailState {
  const CarDetailFailure(this.error);

  final AppFailure error;

  @override
  List<Object?> get props => [error];
}

final class CarDetailLoaded extends CarDetailState {
  const CarDetailLoaded({
    required this.detail,
    required this.isOwner,
    this.start,
    this.end,
    this.quote,
    this.termsAccepted = false,
    this.dateError,
  });

  final VehicleDetail detail;
  final bool isOwner;
  final DateTime? start;
  final DateTime? end;
  final PriceQuote? quote;
  final bool termsAccepted;
  final String? dateError;

  bool get canRequest =>
      !isOwner &&
      termsAccepted &&
      quote != null &&
      dateError == null &&
      start != null &&
      end != null;

  CarDetailLoaded copyWith({
    DateTime? start,
    DateTime? end,
    PriceQuote? quote,
    bool? termsAccepted,
    String? dateError,
    bool clearDateError = false,
    bool clearQuote = false,
  }) {
    return CarDetailLoaded(
      detail: detail,
      isOwner: isOwner,
      start: start ?? this.start,
      end: end ?? this.end,
      quote: clearQuote ? null : (quote ?? this.quote),
      termsAccepted: termsAccepted ?? this.termsAccepted,
      dateError: clearDateError ? null : (dateError ?? this.dateError),
    );
  }

  @override
  List<Object?> get props => [
    detail,
    isOwner,
    start,
    end,
    quote,
    termsAccepted,
    dateError,
  ];
}
