import '../../error/result.dart';

/// A one-time code sent to a phone. [code] is exposed only because the
/// simulation shows it on screen for the demo.
class OtpChallenge {
  const OtpChallenge({required this.phone, required this.code});

  final String phone;
  final String code;
}

/// Phone and identity-document verification. Simulated in this project.
abstract interface class VerificationProvider {
  Future<Result<OtpChallenge>> sendOtp(String phone);

  Future<Result<void>> confirmOtp({
    required OtpChallenge challenge,
    required String code,
  });

  Future<Result<void>> verifyDocument({
    required String documentNumber,
    required String photoUrl,
  });
}
