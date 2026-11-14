import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/core/theme/app_theme.dart';
import 'package:veloce/core/widgets/app_text_field.dart';
import 'package:veloce/core/widgets/field_hints.dart';
import 'package:veloce/core/widgets/locked_contact_tile.dart';
import 'package:veloce/core/widgets/primary_button.dart';
import 'package:veloce/core/widgets/status_chip.dart';

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('a text field shows its placeholder while empty', (tester) async {
    await tester.pumpWidget(
      _host(const AppTextField(label: 'Email', hint: FieldHints.email)),
    );

    expect(find.text(FieldHints.email), findsOneWidget);
  });

  testWidgets('status chip carries the status as text', (tester) async {
    await tester.pumpWidget(_host(StatusChip.booking(BookingStatus.pending)));
    expect(find.text('Pending approval'), findsOneWidget);
  });

  testWidgets('locked contact tile hides details until unlocked', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const LockedContactTile(isLocked: true, phone: '0788123456')),
    );
    expect(find.text('0788123456'), findsNothing);
    expect(find.textContaining('unlock after payment'), findsOneWidget);

    await tester.pumpWidget(
      _host(
        const LockedContactTile(
          isLocked: false,
          phone: '0788123456',
          meetingPoint: 'Kacyiru',
        ),
      ),
    );
    expect(find.text('0788123456'), findsOneWidget);
    expect(find.text('Meet at: Kacyiru'), findsOneWidget);
  });

  testWidgets('primary button ignores taps while loading', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        PrimaryButton(label: 'Pay', onPressed: () => taps++, isLoading: true),
      ),
    );
    await tester.tap(find.byType(FilledButton));
    expect(taps, 0);

    await tester.pumpWidget(
      _host(PrimaryButton(label: 'Pay', onPressed: () => taps++)),
    );
    await tester.tap(find.text('Pay'));
    expect(taps, 1);
  });

  testWidgets('the kit renders without overflow on a small landscape phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(640, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _host(
        SingleChildScrollView(
          child: Column(
            children: [
              StatusChip.booking(BookingStatus.active),
              const LockedContactTile(isLocked: true),
              PrimaryButton(label: 'Continue', onPressed: () {}),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
