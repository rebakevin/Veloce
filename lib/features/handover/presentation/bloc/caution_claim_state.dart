import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/caution_claim.dart';

enum CautionClaimLoad { loading, loaded, failed }

class CautionClaimState extends Equatable {
  const CautionClaimState({
    this.loadStatus = CautionClaimLoad.loading,
    this.claim,
    this.isLoading = false,
    this.isUploading = false,
    this.evidence = const [],
    this.errorMessage,
  });

  /// State of the claim document stream. [claim] is null when none exists.
  final CautionClaimLoad loadStatus;
  final CautionClaim? claim;

  /// True while a submit, respond, revise or refund call is running.
  final bool isLoading;

  /// True while an evidence photo is uploading.
  final bool isUploading;

  /// Evidence photo URLs added in this session, not yet part of the claim.
  final List<String> evidence;
  final String? errorMessage;

  CautionClaimState copyWith({
    CautionClaimLoad? loadStatus,
    CautionClaim? claim,
    bool clearClaim = false,
    bool? isLoading,
    bool? isUploading,
    List<String>? evidence,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CautionClaimState(
      loadStatus: loadStatus ?? this.loadStatus,
      claim: clearClaim ? null : claim ?? this.claim,
      isLoading: isLoading ?? this.isLoading,
      isUploading: isUploading ?? this.isUploading,
      evidence: evidence ?? this.evidence,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    loadStatus,
    claim,
    isLoading,
    isUploading,
    evidence,
    errorMessage,
  ];
}
