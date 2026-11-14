import 'package:veloce/core/error/result.dart';

/// Removes everything the backend holds about one user.
abstract interface class AccountEraser {
  /// Deletes [uid]'s profile and private documents, favourites, notifications,
  /// cars, bookings and everything under them (checklists, ledger rows,
  /// claims, repairs), and every review they wrote or received. Safe to run
  /// again after a failure: it finds what is left and deletes that.
  ///
  /// Uploaded files are removed best effort and may remain.
  Future<Result<void>> eraseAll(String uid);
}
