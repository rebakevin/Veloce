import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:veloce/core/theme/app_theme.dart';
import 'package:veloce/features/profile/presentation/pages/contact_page.dart';
import 'package:veloce/features/profile/presentation/widgets/mail_launcher.dart';

import 'profile_page_harness.dart';

class _MockLauncher extends Mock implements MailLauncher {}

void main() {
  tearDown(resetGetIt);

  testWidgets('tapping the support email opens the mail app', (tester) async {
    final launcher = _MockLauncher();
    when(
      () => launcher.compose(
        to: any(named: 'to'),
        subject: any(named: 'subject'),
      ),
    ).thenAnswer((_) async => true);
    registerMessenger();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ContactPage(launcher: launcher),
      ),
    );

    await tester.tap(find.text('r.kevin@alustudent.com'));

    verify(
      () => launcher.compose(
        to: 'r.kevin@alustudent.com',
        subject: 'Veloce support',
      ),
    ).called(1);
  });

  testWidgets('shows an error when no mail app is available', (tester) async {
    final launcher = _MockLauncher();
    when(
      () => launcher.compose(
        to: any(named: 'to'),
        subject: any(named: 'subject'),
      ),
    ).thenAnswer((_) async => false);
    final messenger = registerMessenger();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        scaffoldMessengerKey: messenger.key,
        home: ContactPage(launcher: launcher),
      ),
    );

    await tester.tap(find.text('r.kevin@alustudent.com'));
    await tester.pump();

    expect(find.textContaining('No email app found'), findsOneWidget);
  });
}
