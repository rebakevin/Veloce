import 'package:equatable/equatable.dart';

import 'car_finance_share.dart';
import 'finance_transaction.dart';

/// Aggregated finances summary for an owner or a single car for a period.
class FinanceSummary extends Equatable {
  const FinanceSummary({
    required this.totalEarned,
    required this.totalLosses,
    required this.transactions,
    required this.carShares,
  });

  final int totalEarned;
  final int totalLosses;
  final List<FinanceTransaction> transactions; // Sorted newest first
  final List<CarFinanceShare> carShares;

  @override
  List<Object?> get props => [
    totalEarned,
    totalLosses,
    transactions,
    carShares,
  ];
}
