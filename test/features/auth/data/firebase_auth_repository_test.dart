import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/auth/data/firebase_auth_data_source.dart';
import 'package:veloce/features/auth/data/firebase_auth_repository.dart';
import 'package:veloce/features/auth/domain/entities/auth_user.dart';

import '../domain/auth_fakes.dart';

class _MockSource extends Mock implements FirebaseAuthDataSource {}

void main() {
  late _MockSource source;
  late FirebaseAuthRepository repository;

  setUp(() {
    source = _MockSource();
    repository = FirebaseAuthRepository(source);
  });

  test('success wraps the user', () async {
    when(() => source.signInWithEmail(email: 'a@b.co', password: 'pw'))
        .thenAnswer((_) async => anAuthUser());

    final result = await repository.signInWithEmail(
      email: 'a@b.co',
      password: 'pw',
    );

    expect((result as Success<AuthUser>).value.uid, 'uid-1');
  });

  test('FirebaseAuthException becomes a mapped failure', () async {
    when(
      () => source.createEmailUser(
        email: any(named: 'email'),
        password: any(named: 'password'),
        displayName: any(named: 'displayName'),
      ),
    ).thenThrow(FirebaseAuthException(code: 'email-already-in-use'));

    final result = await repository.createEmailUser(
      email: 'a@b.co',
      password: 'secret123',
      displayName: 'A',
    );

    expect((result as Failure<AuthUser>).failure, isA<ConflictFailure>());
  });

  test('a timeout is reported as a network failure', () async {
    when(() => source.sendPasswordReset(any()))
        .thenAnswer((_) => Future.error(TimeoutException('slow')));

    final result = await repository.sendPasswordReset('a@b.co');

    expect((result as Failure<void>).failure, isA<NetworkFailure>());
  });
}
