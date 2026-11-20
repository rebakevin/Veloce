import '../../domain/services/verification_provider.dart';
import '../../error/app_failure.dart';
import '../../error/result.dart';

/// Simulated document checks. Flip [shouldSucceed] to demo the
/// verification-failure retry state.
class VerificationSim implements VerificationProvider {
  bool shouldSucceed = true;

  @override
  Future<Result<void>> verifyDocument({
    required String documentNumber,
    required String photoUrl,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!shouldSucceed) {
      return const Result.failure(
        ValidationFailure('We could not verify this document. Try again.'),
      );
    }
    return const Result.success(null);
  }
}
