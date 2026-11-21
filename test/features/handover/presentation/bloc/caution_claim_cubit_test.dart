import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:veloce/core/domain/entities/booking.dart';
import 'package:veloce/core/domain/entities/caution_claim.dart';
import 'package:veloce/core/domain/enums/claim_response.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/handover/presentation/bloc/caution_claim_cubit.dart';
import 'package:veloce/features/handover/presentation/bloc/caution_claim_state.dart';

import '../../../../support/builders.dart';
import 'handover_fakes.dart';

void main() {
  late MockHandoverRepository repository;
  late StreamController<CautionClaim?> claims;

  setUpAll(() => registerFallbackValue(ClaimResponse.none));

  setUp(() {
    repository = MockHandoverRepository();
    claims = StreamController<CautionClaim?>.broadcast();
    addTearDown(claims.close);
    when(() => repository.watchClaim('booking-1'))
        .thenAnswer((_) => claims.stream);
  });

  CautionClaimCubit createCubit() {
    final cubit = CautionClaimCubit(
      bookingId: 'booking-1',
      repository: repository,
      mediaStorage: FakeMediaStorage(),
    );
    addTearDown(cubit.close);
    return cubit;
  }

  const photo = 'https://example.com/photo.jpg';

  Future<CautionClaimCubit> cubitWithPhoto() async {
    final cubit = createCubit();
    await cubit.addEvidence(bytes: Uint8List.fromList([1]), extension: 'jpg');
    return cubit;
  }

  Result<Booking> booking() => Result.success(aBooking());

  test('shows the claim document as it changes', () async {
    final cubit = createCubit();
    expect(cubit.state.loadStatus, CautionClaimLoad.loading);

    claims.add(null);
    await pumpEventQueue();
    expect(cubit.state.loadStatus, CautionClaimLoad.loaded);
    expect(cubit.state.claim, isNull);

    claims.add(aClaim());
    await pumpEventQueue();
    expect(cubit.state.claim, aClaim());
  });

  test('retryLoad resubscribes after a failed load', () async {
    final cubit = createCubit();
    claims.addError(Exception('boom'));
    await pumpEventQueue();
    expect(cubit.state.loadStatus, CautionClaimLoad.failed);

    await cubit.retryLoad();
    expect(cubit.state.loadStatus, CautionClaimLoad.loading);

    claims.add(aClaim());
    await pumpEventQueue();
    expect(cubit.state.loadStatus, CautionClaimLoad.loaded);
  });

  test('a stream error becomes a failed load', () async {
    final cubit = createCubit();

    claims.addError(Exception('boom'));
    await pumpEventQueue();

    expect(cubit.state.loadStatus, CautionClaimLoad.failed);
  });

  group('submitClaim', () {
    test('trims the form and sends the uploaded evidence', () async {
      when(
        () => repository.submitClaim(
          bookingId: any(named: 'bookingId'),
          userId: any(named: 'userId'),
          amount: any(named: 'amount'),
          reason: any(named: 'reason'),
          evidenceUrls: any(named: 'evidenceUrls'),
        ),
      ).thenAnswer((_) async => booking());
      final cubit = await cubitWithPhoto();
      await cubit.addEvidence(bytes: Uint8List.fromList([2]), extension: 'png');

      await cubit.submitClaim(
        userId: 'owner-1',
        amountText: ' 40000 ',
        reason: ' Scratch ',
      );

      verify(
        () => repository.submitClaim(
          bookingId: 'booking-1',
          userId: 'owner-1',
          amount: 40000,
          reason: 'Scratch',
          evidenceUrls: [photo, photo],
        ),
      ).called(1);
      expect(cubit.state.isLoading, false);
      expect(cubit.state.evidence, isEmpty);
      expect(cubit.state.errorMessage, isNull);
    });

    test('rejects an invalid amount or empty reason without calling', () async {
      final cubit = createCubit();

      await cubit.submitClaim(
        userId: 'owner-1',
        amountText: 'abc',
        reason: 'Scratch',
      );

      expect(cubit.state.errorMessage, 'Enter a valid amount and reason.');
      verifyNever(
        () => repository.submitClaim(
          bookingId: any(named: 'bookingId'),
          userId: any(named: 'userId'),
          amount: any(named: 'amount'),
          reason: any(named: 'reason'),
          evidenceUrls: any(named: 'evidenceUrls'),
        ),
      );
    });

    test('requires at least one evidence photo', () async {
      final cubit = createCubit();

      await cubit.submitClaim(
        userId: 'owner-1',
        amountText: '40000',
        reason: 'Scratch',
      );

      expect(cubit.state.errorMessage, 'Add at least one evidence photo.');
      verifyNever(
        () => repository.submitClaim(
          bookingId: any(named: 'bookingId'),
          userId: any(named: 'userId'),
          amount: any(named: 'amount'),
          reason: any(named: 'reason'),
          evidenceUrls: any(named: 'evidenceUrls'),
        ),
      );
    });

    test('removing evidence drops it from the pending list', () async {
      final cubit = await cubitWithPhoto();

      await cubit.removeEvidence(photo);

      expect(cubit.state.evidence, isEmpty);
    });

    test('shows the repository failure', () async {
      when(
        () => repository.submitClaim(
          bookingId: any(named: 'bookingId'),
          userId: any(named: 'userId'),
          amount: any(named: 'amount'),
          reason: any(named: 'reason'),
          evidenceUrls: any(named: 'evidenceUrls'),
        ),
      ).thenAnswer(
        (_) async => const Result.failure(ValidationFailure('Above caution.')),
      );
      final cubit = await cubitWithPhoto();

      await cubit.submitClaim(
        userId: 'owner-1',
        amountText: '999999',
        reason: 'Scratch',
      );

      expect(cubit.state.errorMessage, 'Above caution.');
      expect(cubit.state.isLoading, false);
    });
  });

  group('respondToClaim', () {
    for (final response in [ClaimResponse.agreed, ClaimResponse.disputed]) {
      test('renter ${response.key} is sent to the repository', () async {
        when(
          () => repository.respondToClaim(
            bookingId: any(named: 'bookingId'),
            userId: any(named: 'userId'),
            response: any(named: 'response'),
          ),
        ).thenAnswer((_) async => booking());
        final cubit = createCubit();

        await cubit.respondToClaim(userId: 'renter-1', response: response);

        verify(
          () => repository.respondToClaim(
            bookingId: 'booking-1',
            userId: 'renter-1',
            response: response,
          ),
        ).called(1);
        expect(cubit.state.errorMessage, isNull);
      });
    }

    test('ignores a second tap while a request is running', () async {
      final pending = Completer<Result<Booking>>();
      when(
        () => repository.respondToClaim(
          bookingId: any(named: 'bookingId'),
          userId: any(named: 'userId'),
          response: any(named: 'response'),
        ),
      ).thenAnswer((_) => pending.future);
      final cubit = createCubit();

      final first = cubit.respondToClaim(
        userId: 'renter-1',
        response: ClaimResponse.agreed,
      );
      await cubit.respondToClaim(
        userId: 'renter-1',
        response: ClaimResponse.disputed,
      );
      expect(cubit.state.isLoading, true);
      pending.complete(booking());
      await first;

      verify(
        () => repository.respondToClaim(
          bookingId: any(named: 'bookingId'),
          userId: any(named: 'userId'),
          response: any(named: 'response'),
        ),
      ).called(1);
    });

    test('an unexpected exception becomes a generic message', () async {
      when(
        () => repository.respondToClaim(
          bookingId: any(named: 'bookingId'),
          userId: any(named: 'userId'),
          response: any(named: 'response'),
        ),
      ).thenThrow(StateError('boom'));
      final cubit = createCubit();

      await cubit.respondToClaim(
        userId: 'renter-1',
        response: ClaimResponse.agreed,
      );

      expect(cubit.state.errorMessage, const UnknownFailure().message);
      expect(cubit.state.isLoading, false);
    });
  });

  group('re-claim after a dispute', () {
    test('reviseClaim sends the lower amount', () async {
      when(
        () => repository.reviseClaim(
          bookingId: any(named: 'bookingId'),
          userId: any(named: 'userId'),
          amount: any(named: 'amount'),
          reason: any(named: 'reason'),
          evidenceUrls: any(named: 'evidenceUrls'),
        ),
      ).thenAnswer((_) async => booking());
      final cubit = await cubitWithPhoto();

      await cubit.reviseClaim(
        userId: 'owner-1',
        amountText: '30000',
        reason: 'Smaller scratch',
      );

      verify(
        () => repository.reviseClaim(
          bookingId: 'booking-1',
          userId: 'owner-1',
          amount: 30000,
          reason: 'Smaller scratch',
          evidenceUrls: [photo],
        ),
      ).called(1);
    });

    test(
      'a revision above the original is rejected by the repository',
      () async {
        when(
          () => repository.reviseClaim(
            bookingId: any(named: 'bookingId'),
            userId: any(named: 'userId'),
            amount: any(named: 'amount'),
            reason: any(named: 'reason'),
            evidenceUrls: any(named: 'evidenceUrls'),
          ),
        ).thenAnswer(
          (_) async => const Result.failure(
            ValidationFailure('A revision cannot exceed the original claim.'),
          ),
        );
        final cubit = await cubitWithPhoto();

        await cubit.reviseClaim(
          userId: 'owner-1',
          amountText: '60000',
          reason: 'Bigger',
        );

        expect(
          cubit.state.errorMessage,
          'A revision cannot exceed the original claim.',
        );
      },
    );

    test('refundCaution calls the repository', () async {
      when(
        () => repository.refundCaution(
          bookingId: any(named: 'bookingId'),
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) async => booking());
      final cubit = createCubit();

      await cubit.refundCaution(userId: 'owner-1');

      verify(
        () =>
            repository.refundCaution(bookingId: 'booking-1', userId: 'owner-1'),
      ).called(1);
    });
  });
}
