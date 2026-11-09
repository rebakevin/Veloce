import 'package:equatable/equatable.dart';

/// Long-rental tier: from [fromDays] days every day costs [pricePerDay] RWF.
class LongRate extends Equatable {
  const LongRate({required this.fromDays, required this.pricePerDay});

  final int fromDays;
  final int pricePerDay;

  LongRate copyWith({int? fromDays, int? pricePerDay}) {
    return LongRate(
      fromDays: fromDays ?? this.fromDays,
      pricePerDay: pricePerDay ?? this.pricePerDay,
    );
  }

  @override
  List<Object?> get props => [fromDays, pricePerDay];
}
