import 'package:equatable/equatable.dart';

/// Locked price of a rental, written into the booking at request time.
class PriceQuote extends Equatable {
  const PriceQuote({
    required this.days,
    required this.dailyRateApplied,
    required this.rentalFee,
    required this.platformFee,
    required this.cautionFee,
  });

  final int days;
  final int dailyRateApplied;
  final int rentalFee;

  /// Paid by the owner out of the rental fee.
  final int platformFee;
  final int cautionFee;

  /// What the renter pays: rental fee plus the refundable caution.
  int get totalPayable => rentalFee + cautionFee;

  int get ownerReceives => rentalFee - platformFee;

  @override
  List<Object?> get props => [
    days,
    dailyRateApplied,
    rentalFee,
    platformFee,
    cautionFee,
  ];
}
