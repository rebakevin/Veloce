import 'package:veloce/core/domain/services/verification_provider.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';

class VerifyDocument {
  const VerifyDocument(this._verification);

  final VerificationProvider _verification;

  Future<Result<void>> call(String documentNumber) {
    if (documentNumber.trim().isEmpty) {
      return Future.value(
        const Result.failure(ValidationFailure('Enter the document number.')),
      );
    }
    return _verification.verifyDocument(
      documentNumber: documentNumber.trim(),
      photoUrl: '',
    );
  }
}
