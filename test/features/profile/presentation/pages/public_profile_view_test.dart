import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/theme/app_theme.dart';
import 'package:veloce/features/profile/domain/entities/public_profile.dart';
import 'package:veloce/features/profile/presentation/bloc/public_profile_cubit.dart';
import 'package:veloce/features/profile/presentation/pages/public_profile_page.dart';

class _MockCubit extends MockCubit<PublicProfileState>
    implements PublicProfileCubit {}

void main() {
  late _MockCubit cubit;

  setUp(() => cubit = _MockCubit());

  Future<void> pumpView(WidgetTester tester, PublicProfileState state) async {
    when(() => cubit.state).thenReturn(state);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BlocProvider<PublicProfileCubit>.value(
          value: cubit,
          child: const PublicProfileView(userId: 'u2'),
        ),
      ),
    );
  }

  const first = PublicProfile(
    userId: 'u2',
    name: 'Jean Mugisha',
    photoUrl: null,
    ratingAvg: 0,
    ratingCount: 0,
    completedCount: 0,
  );

  testWidgets('first-time user gets the badge and no contact details', (
    tester,
  ) async {
    await pumpView(tester, const PublicProfileLoaded(first));

    expect(find.text('Jean Mugisha'), findsOneWidget);
    expect(find.text('First-time user'), findsOneWidget);
    expect(find.text('0 past rentals'), findsOneWidget);
    expect(find.text('New'), findsOneWidget);
    expect(find.byIcon(Icons.phone_outlined), findsNothing);
    expect(find.byIcon(Icons.mail_outline), findsNothing);
    expect(find.textContaining('@'), findsNothing);
    expect(find.textContaining('07'), findsNothing);
  });

  testWidgets('experienced user shows rating and rentals, no badge', (
    tester,
  ) async {
    await pumpView(
      tester,
      const PublicProfileLoaded(
        PublicProfile(
          userId: 'u2',
          name: 'Jean Mugisha',
          photoUrl: null,
          ratingAvg: 4.5,
          ratingCount: 6,
          completedCount: 5,
        ),
      ),
    );

    expect(find.text('4.5 (6)'), findsOneWidget);
    expect(find.text('5 past rentals'), findsOneWidget);
    expect(find.text('First-time user'), findsNothing);
  });

  testWidgets('shows a not found message', (tester) async {
    await pumpView(tester, const PublicProfileNotFound());

    expect(find.text('User not found'), findsOneWidget);
  });

  testWidgets('a failure offers Retry', (tester) async {
    when(() => cubit.load()).thenAnswer((_) async {});
    await pumpView(tester, const PublicProfileFailure(NetworkFailure()));
    await tester.tap(find.text('Try again'));
    verify(() => cubit.load()).called(1);
  });
}
