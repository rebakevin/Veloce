import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/domain/enums/auth_provider_kind.dart';
import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/auth/domain/entities/auth_user.dart';
import 'package:veloce/features/auth/domain/entities/google_registration_input.dart';
import 'package:veloce/features/auth/domain/entities/google_sign_in_outcome.dart';
import 'package:veloce/features/auth/domain/usecases/complete_google_registration.dart';
import 'package:veloce/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:veloce/features/auth/domain/usecases/submit_identity_document.dart';

import '../../../support/builders.dart';
import 'auth_fakes.dart';

void main() {
  late FakeAuthRepository auth;
  late FakeRegistrationStore store;

  setUp(() {
    auth = FakeAuthRepository();
    store = FakeRegistrationStore();
  });

  test(
    'first Google sign-in has no profile and continues to role choice',
    () async {
      final result = await SignInWithGoogle(auth: auth, store: store)();

      expect(
        (result as Success<GoogleSignInOutcome>).value,
        isA<NewGoogleUser>(),
      );
    },
  );

  test('returning Google user comes back with their profile', () async {
    store.profile = aUser(role: UserRole.owner);

    final result = await SignInWithGoogle(auth: auth, store: store)();

    final outcome = (result as Success<GoogleSignInOutcome>).value;
    expect(outcome, isA<ReturningGoogleUser>());
    expect((outcome as ReturningGoogleUser).profile.role, UserRole.owner);
  });

  test('a cancelled Google chooser is returned as a failure', () async {
    auth.googleResult = const Result.failure(
      ConflictFailure('Google sign-in was cancelled.'),
    );

    final result = await SignInWithGoogle(auth: auth, store: store)();

    expect(
      (result as Failure<GoogleSignInOutcome>).failure,
      isA<ConflictFailure>(),
    );
  });

  group('CompleteGoogleRegistration', () {
    late CompleteGoogleRegistration complete;
    final input = GoogleRegistrationInput(
      role: UserRole.renter,
      phone: '0788123456',
      dateOfBirth: DateTime(1995, 5, 5),
      document: aRegistration().document,
    );

    setUp(() {
      complete = CompleteGoogleRegistration(
        auth: auth,
        store: store,
        submitDocument: SubmitIdentityDocument(
          storage: FakeMediaStorage(),
          verification: FakeVerification(),
        ),
        clock: const FixedClock(),
      );
    });

    test('writes the profile for the signed-in Google user', () async {
      auth.user = anAuthUser(uid: 'g-1', provider: AuthProviderKind.google);

      final result = await complete(input);

      expect(result, isA<Success<AuthUser>>());
      expect(store.written?.uid, 'g-1');
      expect(store.written?.authProvider, AuthProviderKind.google);
      expect(store.written?.name, 'Aline Uwase');
    });

    test('refuses when nobody is signed in with Google', () async {
      final result = await complete(input);

      expect((result as Failure<AuthUser>).failure, isA<ValidationFailure>());
      expect(store.written, isNull);
    });
  });
}
