import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:veloce/core/domain/entities/booking.dart';
import 'package:veloce/core/domain/enums/claim_response.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/handover/domain/repositories/handover_repository.dart';

import 'caution_claim_state.dart';

class CautionClaimCubit extends Cubit<CautionClaimState> {
  CautionClaimCubit({required HandoverRepository repository})
    : _repository = repository,
      super(const CautionClaimState());

  final HandoverRepository _repository;

  void showError(String message) {
    emit(state.copyWith(errorMessage: message));
  }

  Future<void> submitClaim({
    required String bookingId,
    required String userId,
    required int amount,
    required String reason,
    required List<String> evidenceUrls,
  }) {
    return _runAction(
      () => _repository.submitClaim(
        bookingId: bookingId,
        userId: userId,
        amount: amount,
        reason: reason,
        evidenceUrls: evidenceUrls,
      ),
    );
  }

  Future<void> respondToClaim({
    required String bookingId,
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

  Future<void> reviseClaim({
    required String bookingId,
    required String userId,
    required int amount,
    required String reason,
    required List<String> evidenceUrls,
  }) {
    return _runAction(
      () => _repository.reviseClaim(
        bookingId: bookingId,
        userId: userId,
        amount: amount,
        reason: reason,
        evidenceUrls: evidenceUrls,
      ),
    );
  }

  Future<void> refundCaution({
    required String bookingId,
    required String userId,
  }) {
    return _runAction(
      () => _repository.refundCaution(bookingId: bookingId, userId: userId),
    );
  }

  Future<void> _runAction(Future<Result<Booking>> Function() action) async {
    if (state.isLoading) return;

    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final result = await action();

      result.when(
        success: (_) {
          emit(state.copyWith(isLoading: false, clearError: true));
        },
        failure: (failure) {
          emit(state.copyWith(isLoading: false, errorMessage: failure.message));
        },
      );
    } catch (error) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Something went wrong. Please try again.',
        ),
      );
    }
  }
}
