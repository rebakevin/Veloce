import 'package:veloce/core/error/result.dart';

import '../entities/finance_summary.dart';
import '../entities/renter_payment_item.dart';
import '../enums/finance_period.dart';

/// Contract for owner finances and renter payment history.
abstract interface class FinancesRepository {
  /// Computes owner finances summary for [ownerId] and [period], optionally filtered by [vehicleId].
  Future<Result<FinanceSummary>> getOwnerFinances({
    required String ownerId,
    required FinancePeriod period,
    String? vehicleId,
  });

  /// Computes renter payment history for [renterId], newest first.
  Future<Result<List<RenterPaymentItem>>> getRenterPayments(String renterId);
}
