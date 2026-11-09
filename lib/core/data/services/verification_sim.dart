import 'dart:math';

import '../../domain/services/verification_provider.dart';
import '../../error/app_failure.dart';
import '../../error/result.dart';

/// Simulated phone and document checks. Flip [shouldSucceed] to demo the
/// verification-failure retry state.
class VerificationSim implements VerificationProvider {
  VerificationSim({Random? random}) : _random = random ?? Random.secure();

  final Random _random;

  bool shouldSucceed = true;

  @override
  Future<Result<OtpChallenge>> sendOtp(String phone) async {
    final code = (100000 + _random.nextInt(900000)).toString();
    return Result.success(OtpChallenge(phone: phone, code: code));
  }

  @override
  Future<Result<void>> confirmOtp({
    required OtpChallenge challenge,
    required String code,
  }) async {
    if (!shouldSucceed || code != challenge.code) {
      return const Result.failure(
        ValidationFailure('That code is not correct. Please try again.'),
      );
    }
    return const Result.success(null);
  }

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
