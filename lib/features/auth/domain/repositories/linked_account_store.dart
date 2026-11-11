import 'package:veloce/core/error/result.dart';

import '../entities/linked_account.dart';

/// Accounts linked to this device, kept in secure storage (TECHNICAL.md §6.4).
abstract interface class LinkedAccountStore {
  Future<Result<List<LinkedAccount>>> list();

  /// Adds or replaces the entry for `account.uid`. Email accounts pass the
  /// [password] to keep, Google accounts pass none.
  Future<Result<void>> save(LinkedAccount account, {String? password});

  /// The stored password of an email account, or `null`.
  Future<Result<String?>> passwordOf(String uid);

  Future<Result<void>> remove(String uid);
}
