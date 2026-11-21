import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:veloce/core/data/services/firebase_auth_session.dart';
import 'package:veloce/core/data/services/user_lookup.dart';
import 'package:veloce/core/domain/enums/auth_provider_kind.dart';
import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/domain/services/atomic_write.dart';
import 'package:veloce/core/domain/services/audit_logger.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/auth/data/firestore_registration_store.dart';
import 'package:veloce/features/auth/domain/entities/new_profile.dart';

import '../domain/auth_fakes.dart';

class _MockSession extends Mock implements FirebaseAuthSession {}

class _MockUsers extends Mock implements UserLookup {}

class _MockWrites extends Mock implements AtomicWriteFactory {}

class _MockWrite extends Mock implements AtomicWrite {}

class _MockAudit extends Mock implements AuditLogger {}

void main() {
  late _MockWrite write;
  late _MockAudit audit;
  late _MockSession session;
  late FirestoreRegistrationStore store;

  setUpAll(() => registerFallbackValue(_MockWrite()));

  setUp(() {
    write = _MockWrite();
    audit = _MockAudit();
    session = _MockSession();
    final writes = _MockWrites();
    when(() => writes.begin()).thenReturn(write);
    when(() => write.commit()).thenAnswer((_) async {});
    when(() => session.refresh()).thenAnswer((_) async {});
    store = FirestoreRegistrationStore(
      writes: writes,
      audit: audit,
      users: _MockUsers(),
      session: session,
      clock: const FixedClock(),
    );
  });

  NewProfile profileOf(UserRole role) => NewProfile(
    uid: 'u1',
    role: role,
    name: 'Aline',
    email: 'a@example.com',
    phone: '0788123456',
    dateOfBirth: DateTime(1995, 5, 5),
    authProvider: AuthProviderKind.password,
    documentNumber: 'D-1',
    documentPhotoUrl: 'https://x/photo.jpg',
    licenceExpiry: DateTime(2030, 1, 1),
  );

  List<String> writtenPaths() =>
      verify(() => write.set(captureAny(), any())).captured.cast<String>();

  test(
    'a renter registers user, contact, licence and audit in one batch',
    () async {
      final result = await store.createProfile(profileOf(UserRole.renter));

      expect(result, isA<Success<void>>());
      final paths = writtenPaths();
      expect(paths, hasLength(3));
      expect(paths, contains('users/u1'));
      verify(
        () => audit.record(
          write,
          actorId: 'u1',
          entityType: 'user',
          entityId: 'u1',
          oldState: null,
          newState: 'registered',
        ),
      ).called(1);
      verify(() => write.commit()).called(1);
      verify(() => session.refresh()).called(1);
    },
  );

  test('an owner stores the national ID instead of a licence', () async {
    await store.createProfile(profileOf(UserRole.owner));

    final paths = writtenPaths();
    expect(paths.any((path) => path.contains('identity')), isTrue);
    expect(paths.any((path) => path.contains('licence')), isFalse);
  });

  test(
    'a failed commit is a failure and the session is not refreshed',
    () async {
      when(() => write.commit()).thenThrow(Exception('offline'));

      final result = await store.createProfile(profileOf(UserRole.renter));

      expect(result, isA<Failure<void>>());
      verifyNever(() => session.refresh());
    },
  );
}
