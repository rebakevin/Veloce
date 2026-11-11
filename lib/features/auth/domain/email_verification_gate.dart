import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';

/// Blocks actions that need a confirmed email: sending a request, publishing
/// a vehicle and paying. Later phases call [check] (or [require]) at the start
/// of those actions and show the failure message instead of continuing.
class EmailVerificationGate {
  const EmailVerificationGate(this._session);

  static const String unverifiedMessage =
      'Verify your email address first. We sent you a link when you signed up.';

  final AuthSession _session;

  bool get isVerified => _session.isEmailVerified;

  /// `null` when the user may continue, otherwise the reason to show.
  AppFailure? check() =>
      isVerified ? null : const ValidationFailure(unverifiedMessage);

  /// Same as [check], as a [Result] for use cases that chain on it.
  Result<void> require() {
    final failure = check();
    return failure == null
        ? const Result.success(null)
        : Result.failure(failure);
  }
}
