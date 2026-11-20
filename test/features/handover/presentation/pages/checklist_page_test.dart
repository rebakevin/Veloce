import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:veloce/core/data/services/booking_lookup.dart';
import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/core/domain/enums/checklist_kind.dart';
import 'package:veloce/core/domain/enums/media_type.dart';
import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/domain/services/media_storage.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/handover/domain/repositories/handover_repository.dart';
import 'package:veloce/features/handover/presentation/bloc/checklist_cubit.dart';
import 'package:veloce/features/handover/presentation/pages/checklist_page.dart';

import '../../../../support/builders.dart';
import '../bloc/handover_fakes.dart';

class _MockBookingLookup extends Mock implements BookingLookup {}

class _MockAuthSession extends Mock implements AuthSession {}

void main() {
  final getIt = GetIt.I;

  setUp(() {
    final lookup = _MockBookingLookup();
    when(() => lookup.watch('booking-1')).thenAnswer(
      (_) => Stream.value(
        Result.success(aBooking(status: BookingStatus.confirmed)),
      ),
    );
    final session = _MockAuthSession();
    when(() => session.currentUserId).thenReturn('owner-1');

    getIt
      ..registerSingleton<BookingLookup>(lookup)
      ..registerSingleton<AuthSession>(session)
      ..registerSingleton<MediaStorage>(FakeMediaStorage())
      ..registerSingleton<Clock>(FixedClock())
      ..registerSingleton<HandoverRepository>(MockHandoverRepository());
  });

  tearDown(getIt.reset);

  testWidgets('confirm stays disabled until one photo is attached', (
    tester,
  ) async {
    // Tall enough that the lazy list builds the submit button.
    tester.view
      ..physicalSize = const Size(800, 3000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: ChecklistPage(bookingId: 'booking-1', kind: ChecklistKind.pickup),
      ),
    );
    await tester.pumpAndSettle();

    final submit = find.widgetWithText(FilledButton, 'Submit pickup checklist');
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);

    await tester.runAsync(
      () => tester
          .element(submit)
          .read<ChecklistCubit>()
          .uploadMedia(
            bytes: Uint8List.fromList([1]),
            extension: 'jpg',
            mediaType: MediaType.photo,
          ),
    );
    await tester.pumpAndSettle();

    expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
  });
}
