import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:veloce/core/theme/app_theme.dart';
import 'package:veloce/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:veloce/features/profile/presentation/pages/licence_verify_page.dart';

import 'profile_page_harness.dart';

void main() {
  late MockProfileBloc bloc;

  setUp(() => bloc = MockProfileBloc());

  Future<void> pumpVerify(WidgetTester tester, ProfileAction action) async {
    whenListen(
      bloc,
      const Stream<ProfileState>.empty(),
      initialState: loadedProfile(action: action),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BlocProvider<ProfileBloc>.value(
          value: bloc,
          child: const LicenceVerifyPage(),
        ),
      ),
    );
  }

  testWidgets('a rejected licence shows the reason and Retry', (tester) async {
    await pumpVerify(
      tester,
      const ProfileAction(
        kind: ProfileActionKind.licence,
        status: ProfileActionStatus.verificationFailed,
        message: 'The photo is not readable.',
      ),
    );

    expect(find.text('Verification failed'), findsOneWidget);
    expect(find.text('The photo is not readable.'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    verify(() => bloc.add(const ProfileLicenceRetried())).called(1);
  });

  testWidgets('shows progress while verifying', (tester) async {
    await pumpVerify(
      tester,
      const ProfileAction(
        kind: ProfileActionKind.licence,
        status: ProfileActionStatus.submitting,
      ),
    );

    expect(find.text('Verifying your licence...'), findsOneWidget);
  });
}
