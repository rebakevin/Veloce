import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/booking.dart';
import '../../../../core/domain/enums/claim_response.dart';
import '../../../../core/domain/enums/storage_bucket.dart';
import '../../../../core/domain/services/media_storage.dart';
import '../../../../core/error/app_failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/repositories/handover_repository.dart';
import 'caution_claim_state.dart';

class CautionClaimCubit extends Cubit<CautionClaimState> {
  CautionClaimCubit({
    required this.bookingId,
    required this._repository,
    required this._mediaStorage,
  }) : super(const CautionClaimState()) {
    _listen();
  }

  void _listen() {
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
  final MediaStorage _mediaStorage;
  StreamSubscription<Object?>? _subscription;

  /// Resubscribes to the claim after a failed load.
  Future<void> retryLoad() async {
    await _subscription?.cancel();
    emit(state.copyWith(loadStatus: CautionClaimLoad.loading));
    _listen();
  }

  Future<void> submitClaim({
    required String userId,
    required String amountText,
    required String reason,
  }) {
    return _runClaimForm(
      amountText: amountText,
      reason: reason,
      evidenceUrls: state.evidence,
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
  }) {
    return _runClaimForm(
      amountText: amountText,
      reason: reason,
      // Photos from the first claim stay; new ones are added.
      evidenceUrls: [...?state.claim?.evidenceUrls, ...state.evidence],
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
    required List<String> evidenceUrls,
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

    if (state.isUploading) {
      emit(
        state.copyWith(errorMessage: 'Wait for the photo to finish uploading.'),
      );
      return Future.value();
    }

    if (evidenceUrls.isEmpty) {
      emit(state.copyWith(errorMessage: 'Add at least one evidence photo.'));
      return Future.value();
    }

    return _runAction(() => action(amount, evidenceUrls));
  }

  Future<void> _runAction(Future<Result<Booking>> Function() action) async {
    if (state.isLoading) return;

    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final result = await action();
      if (isClosed) return;

      result.when(
        success: (_) => emit(
          state.copyWith(
            isLoading: false,
            evidence: const [],
            clearError: true,
          ),
        ),
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

  /// Uploads one evidence photo and adds it to the pending evidence.
  Future<void> addEvidence({
    required Uint8List bytes,
    required String extension,
  }) async {
    if (state.isUploading || state.isLoading) return;

    emit(state.copyWith(isUploading: true, clearError: true));

    try {
      final result = await _mediaStorage.upload(
        bytes: bytes,
        extension: extension,
        bucket: StorageBucket.checklistMedia,
      );
      if (isClosed) return;

      result.when(
        success: (url) => emit(
          state.copyWith(
            isUploading: false,
            evidence: [...state.evidence, url],
          ),
        ),
        failure: (failure) => emit(
          state.copyWith(isUploading: false, errorMessage: failure.message),
        ),
      );
    } catch (_) {
      if (isClosed) return;

      emit(
        state.copyWith(
          isUploading: false,
          errorMessage: const UnknownFailure().message,
        ),
      );
    }
  }

  /// Removes a pending evidence photo (best effort delete of the file).
  Future<void> removeEvidence(String url) async {
    emit(
      state.copyWith(
        evidence: state.evidence.where((item) => item != url).toList(),
        clearError: true,
      ),
    );

    await _mediaStorage.delete(url);
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
