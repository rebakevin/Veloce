import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:veloce/core/data/services/failure_mapper.dart';
import 'package:veloce/core/error/result.dart';

import '../domain/entities/linked_account.dart';
import '../domain/repositories/linked_account_store.dart';
import 'linked_account_codec.dart';

/// [LinkedAccountStore] in `flutter_secure_storage` (Keychain / Keystore). The
/// list is one JSON entry and each email password has its own key.
class SecureLinkedAccountStore implements LinkedAccountStore {
  const SecureLinkedAccountStore(this._storage);

  static const String _listKey = 'linked_accounts';
  static const String _passwordPrefix = 'linked_password_';

  final FlutterSecureStorage _storage;

  @override
  Future<Result<List<LinkedAccount>>> list() => _guard(_read);

  @override
  Future<Result<void>> save(LinkedAccount account, {String? password}) {
    return _guard(() async {
      final accounts = await _read();
      final updated = [
        for (final existing in accounts)
          if (existing.uid != account.uid) existing,
        account,
      ];
      await _storage.write(
        key: _listKey,
        value: LinkedAccountCodec.encode(updated),
      );
      final key = _passwordKey(account.uid);
      if (password == null) {
        await _storage.delete(key: key);
      } else {
        await _storage.write(key: key, value: password);
      }
    });
  }

  @override
  Future<Result<String?>> passwordOf(String uid) =>
      _guard(() => _storage.read(key: _passwordKey(uid)));

  @override
  Future<Result<void>> remove(String uid) {
    return _guard(() async {
      final accounts = await _read();
      await _storage.write(
        key: _listKey,
        value: LinkedAccountCodec.encode([
          for (final account in accounts)
            if (account.uid != uid) account,
        ]),
      );
      await _storage.delete(key: _passwordKey(uid));
    });
  }

  Future<List<LinkedAccount>> _read() async {
    final source = await _storage.read(key: _listKey);
    return source == null ? const [] : LinkedAccountCodec.decode(source);
  }

  String _passwordKey(String uid) => '$_passwordPrefix$uid';

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Result.success(await action());
    } on Object catch (error, stackTrace) {
      return Result.failure(mapToFailure(error, stackTrace));
    }
  }
}
