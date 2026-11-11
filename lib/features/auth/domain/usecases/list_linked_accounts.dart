import 'package:veloce/core/error/result.dart';

import '../entities/linked_account.dart';
import '../repositories/linked_account_store.dart';

/// Accounts linked to this device, for the account switcher.
class ListLinkedAccounts {
  const ListLinkedAccounts(this._store);

  final LinkedAccountStore _store;

  Future<Result<List<LinkedAccount>>> call() => _store.list();
}
