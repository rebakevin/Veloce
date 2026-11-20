import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/theme/app_theme.dart';
import 'package:veloce/features/booking/presentation/bloc/booking_detail_bloc.dart';
import 'package:veloce/features/booking/presentation/pages/booking_detail_page.dart';

import '../../support/booking_test_data.dart';

class _MockBookingDetailBloc
    extends MockBloc<BookingDetailEvent, BookingDetailState>
    implements BookingDetailBloc {}

void main() {
  testWidgets('booking detail does not overflow in landscape', (tester) async {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final bloc = _MockBookingDetailBloc();
    final view = bookingView(status: BookingStatus.confirmed);
    whenListen(
      bloc,
      const Stream<BookingDetailState>.empty(),
      initialState: BookingDetailLoaded(view: view, role: UserRole.renter),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BlocProvider<BookingDetailBloc>.value(
          value: bloc,
          child: const BookingDetailView(bookingId: 'booking-1'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Booking'), findsOneWidget);
    expect(find.text(view.booking.reference), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
