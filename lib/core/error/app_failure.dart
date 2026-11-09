import 'package:equatable/equatable.dart';

/// Why an operation failed. Repositories return these instead of throwing.
sealed class AppFailure extends Equatable {
  const AppFailure(this.message);

  /// Plain-English text that is safe to show to a user.
  final String message;

  @override
  List<Object?> get props => [message];
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure([
    super.message = 'No connection. Check your internet and try again.',
  ]);
}

/// Firestore rules rejected the write, usually a lost race or a changed state.
final class PermissionFailure extends AppFailure {
  const PermissionFailure([
    super.message = 'This changed while you were working. Please refresh.',
  ]);
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message);
}

/// A business rule blocked the action (dates taken, renter already booked).
final class ConflictFailure extends AppFailure {
  const ConflictFailure(super.message);
}

final class NotFoundFailure extends AppFailure {
  const NotFoundFailure([super.message = 'We could not find that.']);
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure([
    super.message = 'Something went wrong. Please try again.',
  ]);
}
