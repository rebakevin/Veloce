import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:veloce/core/domain/entities/booking.dart';
import 'package:veloce/core/domain/enums/booking_actor.dart';
import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/core/domain/enums/checklist_kind.dart';
import 'package:veloce/core/domain/enums/checklist_side.dart';
import 'package:veloce/core/domain/enums/media_type.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/handover/presentation/bloc/checklist_cubit.dart';
import 'package:veloce/features/handover/presentation/bloc/checklist_state.dart';

import '../../../../support/builders.dart';
import 'handover_fakes.dart';

void main() {
  late MockHandoverRepository repository;

  setUpAll(() {
    registerFallbackValue(ChecklistKind.pickup);
    registerFallbackValue(ChecklistSide.owner);
    registerFallbackValue(BookingActor.owner);
    registerFallbackValue(<Never>[]);
  });

  setUp(() {
    repository = MockHandoverRepository();
    when(
      () => repository.saveChecklist(
        bookingId: any(named: 'bookingId'),
        kind: any(named: 'kind'),
        side: any(named: 'side'),
        entries: any(named: 'entries'),
        media: any(named: 'media'),
      ),
    ).thenAnswer((_) async => const Result<void>.success(null));
  });

  void stubPickup(Result<Booking> result) {
    when(
      () => repository.confirmPickup(
        bookingId: any(named: 'bookingId'),
        userId: any(named: 'userId'),
        actor: any(named: 'actor'),
      ),
    ).thenAnswer((_) async => result);
  }

  Future<ChecklistCubit> readyCubit({
    ChecklistKind kind = ChecklistKind.pickup,
    BookingActor actor = BookingActor.owner,
    bool startReturnFirst = false,
    bool withPhoto = true,
  }) async {
    final cubit = ChecklistCubit(
      bookingId: 'booking-1',
      userId: actor == BookingActor.owner ? 'owner-1' : 'renter-1',
      kind: kind,
      actor: actor,
      side: actor == BookingActor.owner
          ? ChecklistSide.owner
          : ChecklistSide.renter,
      startReturnFirst: startReturnFirst,
      mediaStorage: FakeMediaStorage(),
      repository: repository,
      clock: FixedClock(),
    );
    addTearDown(cubit.close);
    if (withPhoto) {
      await cubit.uploadMedia(
        bytes: Uint8List.fromList([1]),
        extension: 'jpg',
        mediaType: MediaType.photo,
      );
    }
    return cubit;
  }

  group('pickup', () {
    test(
      'first side only: saves the checklist and confirms that actor',
      () async {
        // Only the owner has confirmed, so the booking stays confirmed.
        stubPickup(Result.success(aBooking(status: BookingStatus.confirmed)));
        final cubit = await readyCubit();

        await cubit.submit();

        verify(
          () => repository.confirmPickup(
            bookingId: 'booking-1',
            userId: 'owner-1',
            actor: BookingActor.owner,
          ),
        ).called(1);
        expect(cubit.state.submitStatus, ChecklistSubmitStatus.submitted);
        expect(cubit.state.submitMessage, 'Pickup checklist submitted.');
      },
    );

    test(
      'second side: confirms the renter and the booking turns active',
      () async {
        stubPickup(Result.success(aBooking(status: BookingStatus.active)));
        final cubit = await readyCubit(actor: BookingActor.renter);

        await cubit.submit();

        verify(
          () => repository.confirmPickup(
            bookingId: 'booking-1',
            userId: 'renter-1',
            actor: BookingActor.renter,
          ),
        ).called(1);
        expect(cubit.state.submitStatus, ChecklistSubmitStatus.submitted);
      },
    );

    test('saves one entry per checklist item before confirming', () async {
      stubPickup(Result.success(aBooking(status: BookingStatus.confirmed)));
      final cubit = await readyCubit();
      cubit.toggleItem(cubit.checklistItems.first);

      await cubit.submit();

      final entries =
          verify(
                () => repository.saveChecklist(
                  bookingId: 'booking-1',
                  kind: ChecklistKind.pickup,
                  side: ChecklistSide.owner,
                  entries: captureAny(named: 'entries'),
                  media: any(named: 'media'),
                ),
              ).captured.single
              as List;
      expect(entries, hasLength(cubit.checklistItems.length));
    });

    test('does nothing without a photo', () async {
      final cubit = await readyCubit(withPhoto: false);

      await cubit.submit();

      verifyNever(
        () => repository.saveChecklist(
          bookingId: any(named: 'bookingId'),
          kind: any(named: 'kind'),
          side: any(named: 'side'),
          entries: any(named: 'entries'),
          media: any(named: 'media'),
        ),
      );
      expect(cubit.state.submitStatus, ChecklistSubmitStatus.idle);
    });

    test(
      'a failed confirmation reports the message and can be retried',
      () async {
        stubPickup(const Result.failure(ConflictFailure('Already confirmed.')));
        final cubit = await readyCubit();

        await cubit.submit();

        expect(cubit.state.submitStatus, ChecklistSubmitStatus.failed);
        expect(cubit.state.submitMessage, 'Already confirmed.');
        expect(cubit.state.canConfirm, true);
      },
    );

    test('a failed save never confirms', () async {
      when(
        () => repository.saveChecklist(
          bookingId: any(named: 'bookingId'),
          kind: any(named: 'kind'),
          side: any(named: 'side'),
          entries: any(named: 'entries'),
          media: any(named: 'media'),
        ),
      ).thenAnswer((_) async => const Result.failure(NetworkFailure()));
      final cubit = await readyCubit();

      await cubit.submit();

      verifyNever(
        () => repository.confirmPickup(
          bookingId: any(named: 'bookingId'),
          userId: any(named: 'userId'),
          actor: any(named: 'actor'),
        ),
      );
      expect(cubit.state.submitStatus, ChecklistSubmitStatus.failed);
    });
  });

  group('return', () {
    void stubReturn({Result<Booking>? start, Result<Booking>? confirm}) {
      when(
        () => repository.startReturn(
          bookingId: any(named: 'bookingId'),
          userId: any(named: 'userId'),
          actor: any(named: 'actor'),
        ),
      ).thenAnswer(
        (_) async =>
            start ?? Result.success(aBooking(status: BookingStatus.returning)),
      );
      when(
        () => repository.confirmReturn(
          bookingId: any(named: 'bookingId'),
          userId: any(named: 'userId'),
          actor: any(named: 'actor'),
        ),
      ).thenAnswer(
        (_) async =>
            confirm ??
            Result.success(aBooking(status: BookingStatus.returning)),
      );
    }

    test('starts the return first when the booking is still active', () async {
      stubReturn();
      final cubit = await readyCubit(
        kind: ChecklistKind.returning,
        startReturnFirst: true,
      );

      await cubit.submit();

      verifyInOrder([
        () => repository.startReturn(
          bookingId: 'booking-1',
          userId: 'owner-1',
          actor: BookingActor.owner,
        ),
        () => repository.confirmReturn(
          bookingId: 'booking-1',
          userId: 'owner-1',
          actor: BookingActor.owner,
        ),
      ]);
      expect(cubit.state.submitMessage, 'Return checklist submitted.');
    });

    test('skips startReturn once the return has started', () async {
      stubReturn();
      final cubit = await readyCubit(kind: ChecklistKind.returning);

      await cubit.submit();

      verifyNever(
        () => repository.startReturn(
          bookingId: any(named: 'bookingId'),
          userId: any(named: 'userId'),
          actor: any(named: 'actor'),
        ),
      );
      expect(cubit.state.submitStatus, ChecklistSubmitStatus.submitted);
    });

    test('a failed start never confirms the return', () async {
      stubReturn(start: const Result.failure(PermissionFailure()));
      final cubit = await readyCubit(
        kind: ChecklistKind.returning,
        startReturnFirst: true,
      );

      await cubit.submit();

      verifyNever(
        () => repository.confirmReturn(
          bookingId: any(named: 'bookingId'),
          userId: any(named: 'userId'),
          actor: any(named: 'actor'),
        ),
      );
      expect(cubit.state.submitStatus, ChecklistSubmitStatus.failed);
    });
  });
}
