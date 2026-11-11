import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/domain/enums/auth_provider_kind.dart';
import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/auth/data/linked_account_codec.dart';
import 'package:veloce/features/auth/data/secure_linked_account_store.dart';
import 'package:veloce/features/auth/domain/entities/linked_account.dart';

/// In-memory stand-in for the platform keychain.
class _MemorySecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> values = {};

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => values[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => values.remove(key);
}

void main() {
  const alice = LinkedAccount(
    uid: 'u1',
    email: 'a@b.co',
    name: 'Alice',
    role: UserRole.renter,
    authType: AuthProviderKind.password,
  );
  const bob = LinkedAccount(
    uid: 'u2',
    email: 'b@b.co',
    name: 'Bob',
    role: UserRole.owner,
    authType: AuthProviderKind.google,
  );

  late _MemorySecureStorage backing;
  late SecureLinkedAccountStore store;

  setUp(() {
    backing = _MemorySecureStorage();
    store = SecureLinkedAccountStore(backing);
  });

  test('codec round-trips accounts', () {
    expect(LinkedAccountCodec.decode(LinkedAccountCodec.encode([alice, bob])), [
      alice,
      bob,
    ]);
  });

  test('save, list, replace and remove', () async {
    await store.save(alice, password: 'pw-1');
    await store.save(bob);
    await store.save(alice.copyName('Alice B'), password: 'pw-2');

    final listed = (await store.list() as Success<List<LinkedAccount>>).value;
    expect(listed.map((account) => account.name), ['Bob', 'Alice B']);
    expect((await store.passwordOf('u1') as Success<String?>).value, 'pw-2');
    expect((await store.passwordOf('u2') as Success<String?>).value, isNull);

    await store.remove('u1');
    expect((await store.list() as Success<List<LinkedAccount>>).value, [bob]);
    expect(backing.values.keys, isNot(contains('linked_password_u1')));
  });

  test('the credential never appears in the stored list', () async {
    await store.save(alice, password: 'pw-1');

    expect(backing.values['linked_accounts'], isNot(contains('pw-1')));
  });
}

extension on LinkedAccount {
  LinkedAccount copyName(String name) => LinkedAccount(
    uid: uid,
    email: email,
    name: name,
    role: role,
    authType: authType,
  );
}
