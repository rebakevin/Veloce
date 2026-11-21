import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/booking.dart';
import '../../../../core/error/app_failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/repositories/handover_repository.dart';
import 'settlement_state.dart';

/// Runs the no-issue settlement actions: the owner confirms (and may adjust
/// the late fee), then the renter acknowledges. The booking itself comes from the booking stream.
class SettlementCubit extends Cubit<SettlementState> {
  SettlementCubit({required this.bookingId, required this._repository})
    : super(const SettlementState());

  final String bookingId;
  final HandoverRepository _repository;

  Future<void> markNoIssue({required String userId}) {
    return _run(
      () => _repository.markNoIssue(bookingId: bookingId, userId: userId),
    );
  }

  /// Owner: waive the late fee, reduce it, or (neither) restore it.
  Future<void> adjustLateFee({
    required String userId,
    bool waived = false,
    String? reducedFeeText,
  }) {
    int? reducedFee;

    if (reducedFeeText != null) {
      reducedFee = int.tryParse(reducedFeeText.trim());

      if (reducedFee == null || reducedFee <= 0) {
        emit(
          const SettlementState(
            status: SettlementStatus.failure,
            message: 'Enter a reduced fee above 0, or waive the fee.',
          ),
        );
        return Future.value();
      }
    }

    return _run(
      () => _repository.adjustLateFee(
        bookingId: bookingId,
        userId: userId,
        waived: waived,
        reducedFee: reducedFee,
      ),
    );
  }

  Future<void> acknowledgeNoIssue({required String userId}) {
    return _run(
      () =>
          _repository.acknowledgeNoIssue(bookingId: bookingId, userId: userId),
    );
  }

  Future<void> _run(Future<Result<Booking>> Function() action) async {
    if (state.isLoading) return;

    emit(const SettlementState(status: SettlementStatus.loading));

    try {
      final result = await action();
      if (isClosed) return;

      result.when(
        success: (_) => emit(const SettlementState()),
        failure: (failure) => emit(
          SettlementState(
            status: SettlementStatus.failure,
            message: failure.message,
          ),
        ),
      );
    } catch (_) {
      if (isClosed) return;

      emit(
        SettlementState(
          status: SettlementStatus.failure,
          message: const UnknownFailure().message,
        ),
      );
    }
  }
}
