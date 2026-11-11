import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/auth/domain/entities/auth_user.dart';
import 'package:veloce/features/auth/domain/usecases/login_with_email.dart';
import 'package:veloce/features/auth/domain/usecases/send_password_reset.dart';

import 'auth_fakes.dart';

void main() {
  late FakeAuthRepository auth;
  late LoginWithEmail login;

  setUp(() {
    auth = FakeAuthRepository();
    login = LoginWithEmail(auth);
  });

  test('signs in with a trimmed email', () async {
    final result = await login(email: ' a@b.co ', password: 'whatever');

    expect(result, isA<Success<AuthUser>>());
    expect(auth.calls, ['signInEmail:a@b.co:whatever']);
  });

  test('blank or malformed fields never reach Firebase', () async {
    final blankEmail = await login(email: '', password: 'x');
    final badEmail = await login(email: 'nope', password: 'x');
    final blankPassword = await login(email: 'a@b.co', password: '');

    for (final result in [blankEmail, badEmail, blankPassword]) {
      expect((result as Failure<AuthUser>).failure, isA<ValidationFailure>());
    }
    expect(auth.calls, isEmpty);
  });

  test('passes repository failures through unchanged', () async {
    auth.signInResult = const Result.failure(
      ValidationFailure('Wrong email or password.'),
    );

    final result = await login(email: 'a@b.co', password: 'x');

    expect(
      (result as Failure<AuthUser>).failure.message,
      'Wrong email or password.',
    );
  });

  test('password reset validates the email first', () async {
    final reset = SendPasswordReset(auth);

    final bad = await reset('not-an-email');
    final good = await reset(' a@b.co ');

    expect((bad as Failure<void>).failure, isA<ValidationFailure>());
    expect(good, isA<Success<void>>());
    expect(auth.calls, ['reset:a@b.co']);
  });
}
