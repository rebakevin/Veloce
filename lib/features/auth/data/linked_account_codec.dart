import 'dart:convert';

import 'package:veloce/core/domain/enums/auth_provider_kind.dart';
import 'package:veloce/core/domain/enums/user_role.dart';

import '../domain/entities/linked_account.dart';

/// Encodes the linked-account list as JSON for secure storage. Passwords are
/// stored separately and never appear here.
abstract final class LinkedAccountCodec {
  static String encode(List<LinkedAccount> accounts) =>
      jsonEncode(accounts.map(_toMap).toList());

  /// Throws a [FormatException] for a malformed or tampered payload.
  static List<LinkedAccount> decode(String source) {
    final raw = jsonDecode(source);
    if (raw is! List<dynamic>) {
      throw const FormatException('Linked accounts must be a list');
    }
    return raw.map((item) => _fromMap(item as Map<String, dynamic>)).toList();
  }

  static Map<String, dynamic> _toMap(LinkedAccount account) => {
    'uid': account.uid,
    'email': account.email,
    'name': account.name,
    'role': account.role.key,
    'authType': account.authType.key,
  };

  static LinkedAccount _fromMap(Map<String, dynamic> map) => LinkedAccount(
    uid: map['uid'] as String,
    email: map['email'] as String,
    name: map['name'] as String,
    role: UserRole.fromKey(map['role'] as String),
    authType: AuthProviderKind.fromKey(map['authType'] as String),
  );
}
