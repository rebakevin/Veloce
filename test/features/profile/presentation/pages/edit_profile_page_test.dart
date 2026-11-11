import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:veloce/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:veloce/features/profile/presentation/pages/edit_profile_page.dart';

import 'profile_page_harness.dart';

void main() {
  late MockProfileBloc bloc;

  setUpAll(() => registerFallbackValue(const ProfileStarted()));

  setUp(() => bloc = MockProfileBloc());

  tearDown(resetGetIt);

  Future<void> pumpEdit(
    WidgetTester tester, {
    Stream<ProfileState> states = const Stream.empty(),
    ProfileLoaded? initial,
    bool pushed = false,
  }) async {
    whenListen(bloc, states, initialState: initial ?? loadedProfile());
    final router = testRouter(
      home: const EditProfilePage(),
      initial: pushed ? '/start' : '/home',
    );
    await tester.pumpWidget(
      routerApp(
        router,
        registerMessenger(),
        providers: [BlocProvider<ProfileBloc>.value(value: bloc)],
      ),
    );
    if (pushed) {
      unawaited(router.push('/home'));
      await tester.pumpAndSettle();
    }
  }

  testWidgets('prefills the fields from the profile', (tester) async {
    await pumpEdit(tester);

    final typed = tester
        .widgetList<EditableText>(find.byType(EditableText))
        .map((field) => field.controller.text);
    expect(typed, containsAll(['Aline Uwase', '0788123456']));
    expect(find.byType(TextFormField).at(1), findsOneWidget);
    expect(find.text('20 May 1995'), findsOneWidget);
  });

  testWidgets('shows inline errors and sends nothing when invalid', (
    tester,
  ) async {
    await pumpEdit(tester);

    await tester.enterText(find.byType(TextFormField).at(0), '');
    await tester.enterText(find.byType(TextFormField).at(1), '123');
    await tester.scrollUntilVisible(
      find.text('Save changes'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Save changes'));
    await tester.pump();

    expect(find.text('Name is required.'), findsOneWidget);
    expect(find.textContaining('valid Rwandan number'), findsOneWidget);
    verifyNever(() => bloc.add(any(that: isA<ProfileUpdateSubmitted>())));
  });

  testWidgets('dispatches the update when the form is valid', (tester) async {
    await pumpEdit(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'Aline N. Uwase');
    await tester.scrollUntilVisible(
      find.text('Save changes'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Save changes'));
    await tester.pump();

    final update =
        verify(() => bloc.add(captureAny(that: isA<ProfileUpdateSubmitted>())))
                .captured
                .single
            as ProfileUpdateSubmitted;
    expect(update.update.name, 'Aline N. Uwase');
    expect(update.update.phone, '0788123456');
  });

  testWidgets('on success it acknowledges and goes back', (tester) async {
    await pumpEdit(
      tester,
      pushed: true,
      states: Stream.value(
        loadedProfile(
          action: const ProfileAction(
            kind: ProfileActionKind.updateProfile,
            status: ProfileActionStatus.success,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    verify(() => bloc.add(const ProfileActionAcknowledged()))
        .called(greaterThan(0));
    expect(find.text('start page'), findsOneWidget);
  });
}
