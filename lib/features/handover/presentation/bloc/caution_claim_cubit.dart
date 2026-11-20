import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/booking.dart';
import '../../../../core/domain/enums/claim_response.dart';
import '../../../../core/error/app_failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/repositories/handover_repository.dart';
import 'caution_claim_state.dart';

class CautionClaimCubit extends Cubit<CautionClaimState> {
  CautionClaimCubit({required this.bookingId, required this._repository})
    : super(const CautionClaimState()) {
    _subscription = _repository
        .watchClaim(bookingId)
        .listen(
          (claim) => emit(
            state.copyWith(
              loadStatus: CautionClaimLoad.loaded,
              claim: claim,
              clearClaim: claim == null,
            ),
          ),
          onError: (_) =>
              emit(state.copyWith(loadStatus: CautionClaimLoad.failed)),
        );
  }

  final String bookingId;
  final HandoverRepository _repository;
  StreamSubscription<Object?>? _subscription;

  Future<void> submitClaim({
    required String userId,
    required String amountText,
    required String reason,
    required String evidenceText,
  }) {
    return _runClaimForm(
      amountText: amountText,
      reason: reason,
      evidenceText: evidenceText,
      action: (amount, evidenceUrls) => _repository.submitClaim(
        bookingId: bookingId,
        userId: userId,
        amount: amount,
        reason: reason.trim(),
        evidenceUrls: evidenceUrls,
      ),
    );
  }

  Future<void> respondToClaim({
    required String userId,
    required ClaimResponse response,
  }) {
    return _runAction(
      () => _repository.respondToClaim(
        bookingId: bookingId,
        userId: userId,
        response: response,
      ),
    );
  }

  /// The owner's re-claim after a dispute (same or lower amount).
  Future<void> reviseClaim({
    required String userId,
    required String amountText,
    required String reason,
    required String evidenceText,
  }) {
    return _runClaimForm(
      amountText: amountText,
      reason: reason,
      evidenceText: evidenceText,
      action: (amount, evidenceUrls) => _repository.reviseClaim(
        bookingId: bookingId,
        userId: userId,
        amount: amount,
        reason: reason.trim(),
        evidenceUrls: evidenceUrls,
      ),
    );
  }

  Future<void> refundCaution({required String userId}) {
    return _runAction(
      () => _repository.refundCaution(bookingId: bookingId, userId: userId),
    );
  }

  Future<void> _runClaimForm({
    required String amountText,
    required String reason,
    required String evidenceText,
    required Future<Result<Booking>> Function(
      int amount,
      List<String> evidenceUrls,
    )
    action,
  }) {
    final amount = int.tryParse(amountText.trim());

    if (amount == null || amount <= 0 || reason.trim().isEmpty) {
      emit(state.copyWith(errorMessage: 'Enter a valid amount and reason.'));
      return Future.value();
    }

    final evidenceUrls = evidenceText
        .split(',')
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toList();

    return _runAction(() => action(amount, evidenceUrls));
  }

  Future<void> _runAction(Future<Result<Booking>> Function() action) async {
    if (state.isLoading) return;

    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final result = await action();
      if (isClosed) return;

      result.when(
        success: (_) =>
            emit(state.copyWith(isLoading: false, clearError: true)),
        failure: (failure) => emit(
          state.copyWith(isLoading: false, errorMessage: failure.message),
        ),
      );
    } catch (_) {
      if (isClosed) return;

      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: const UnknownFailure().message,
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
