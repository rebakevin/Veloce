import 'package:equatable/equatable.dart';

class CautionClaimState extends Equatable {
  const CautionClaimState({this.isLoading = false, this.errorMessage});

  final bool isLoading;
  final String? errorMessage;

  CautionClaimState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CautionClaimState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, errorMessage];
}
