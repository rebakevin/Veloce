import 'package:veloce/core/error/result.dart';

import '../repositories/linked_account_store.dart';

/// Removes an account from this device only; the account itself is untouched.
class RemoveLinkedAccount {
  const RemoveLinkedAccount(this._store);

  final LinkedAccountStore _store;

  Future<Result<void>> call(String uid) => _store.remove(uid);
}
