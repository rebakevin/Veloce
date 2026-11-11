import 'package:flutter_test/flutter_test.dart';

import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/auth/domain/email_verification_gate.dart';

class _Session implements AuthSession {
  _Session({required this.isEmailVerified});

  @override
  final bool isEmailVerified;

  @override
  String? get currentUserId => 'uid-1';

  @override
  UserRole? get role => UserRole.renter;

  @override
  Stream<void> get changes => const Stream.empty();
}

void main() {
  test('lets a verified user continue', () {
    final gate = EmailVerificationGate(_Session(isEmailVerified: true));
    expect(gate.check(), isNull);
    expect(gate.require(), isA<Success<void>>());
  });

  test('blocks an unverified user with a message', () {
    final gate = EmailVerificationGate(_Session(isEmailVerified: false));
    expect(gate.check()?.message, EmailVerificationGate.unverifiedMessage);
    expect(gate.require(), isA<Failure<void>>());
  });
}
