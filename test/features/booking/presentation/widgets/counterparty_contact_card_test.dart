import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/domain/entities/booking_contact.dart';
import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/core/domain/enums/checklist_side.dart';
import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/theme/app_theme.dart';
import 'package:veloce/features/booking/presentation/widgets/counterparty_contact_card.dart';

import '../../support/booking_test_data.dart';

void main() {
  const contact = BookingContact(
    side: ChecklistSide.owner,
    bookingId: 'booking-1',
    phone: '0788123456',
    email: 'owner@example.com',
    meetingPoint: 'Kacyiru roundabout',
  );

  Future<void> pump(
    WidgetTester tester, {
    required BookingStatus status,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: CounterpartyContactCard(
            view: bookingView(status: status),
            role: UserRole.renter,
            contact: contact,
          ),
        ),
      ),
    );
  }

  testWidgets('stays locked before payment', (tester) async {
    await pump(tester, status: BookingStatus.approved);

    expect(find.text('Contact details unlock after payment.'), findsOneWidget);
    expect(find.text('0788123456'), findsNothing);
    expect(find.text('owner@example.com'), findsNothing);
  });

  testWidgets('reveals the data after payment', (tester) async {
    await pump(tester, status: BookingStatus.confirmed);

    expect(find.text('Contact details unlock after payment.'), findsNothing);
    expect(find.text('0788123456'), findsOneWidget);
    expect(find.text('owner@example.com'), findsOneWidget);
    expect(find.text('Meet at: Kacyiru roundabout'), findsOneWidget);
  });
}
