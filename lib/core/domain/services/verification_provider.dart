import '../../error/result.dart';

/// Identity-document verification. Simulated in this project.
abstract interface class VerificationProvider {
  Future<Result<void>> verifyDocument({
    required String documentNumber,
    required String photoUrl,
  });
}
