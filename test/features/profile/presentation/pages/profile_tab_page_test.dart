import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/features/auth/auth.dart';
import 'package:veloce/features/profile/presentation/bloc/delete_account_cubit.dart';
import 'package:veloce/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:veloce/features/profile/presentation/pages/profile_tab_page.dart';

import 'profile_page_harness.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _MockDeleteAccountCubit extends MockCubit<DeleteAccountState>
    implements DeleteAccountCubit {}

void registerGetItDeleteCubit() {
  GetIt.instance.registerFactory<DeleteAccountCubit>(() {
    final cubit = _MockDeleteAccountCubit();
    when(() => cubit.state).thenReturn(const DeleteAccountIdle());
    return cubit;
  });
}

void main() {
  late MockProfileBloc profileBloc;
  late _MockAuthBloc authBloc;

  setUpAll(() => registerFallbackValue(const SignOutRequested()));

  setUp(() {
    profileBloc = MockProfileBloc();
    authBloc = _MockAuthBloc();
    when(() => authBloc.state).thenReturn(const AuthUnknown());
  });

  tearDown(resetGetIt);

  Future<void> pumpTab(WidgetTester tester, ProfileLoaded state) async {
    whenListen(
      profileBloc,
      const Stream<ProfileState>.empty(),
      initialState: state,
    );
    final router = testRouter(
      home: const ProfileTabPage(),
      stubs: [RouteNames.profileEdit],
    );
    await tester.pumpWidget(
      routerApp(
        router,
        registerMessenger(),
        providers: [
          BlocProvider<ProfileBloc>.value(value: profileBloc),
          BlocProvider<AuthBloc>.value(value: authBloc),
        ],
      ),
    );
  }

  testWidgets('shows the renter account data and renter links', (tester) async {
    await pumpTab(tester, loadedProfile());

    expect(find.text('Aline Uwase'), findsOneWidget);
    expect(find.text('Renter'), findsOneWidget);
    expect(find.text('0788123456'), findsOneWidget);
    expect(find.text('aline@example.com'), findsOneWidget);
    expect(find.text('Identity verified'), findsOneWidget);
    expect(find.text('Driving licence'), findsOneWidget);
    expect(find.text('National ID'), findsNothing);
  });

  testWidgets('shows the owner links instead of renter ones', (tester) async {
    await pumpTab(tester, loadedProfile(role: UserRole.owner));

    expect(find.text('Car owner'), findsOneWidget);
    expect(find.text('Payment method'), findsOneWidget);
    expect(find.text('National ID'), findsOneWidget);
    expect(find.text('Driving licence'), findsNothing);
  });

  testWidgets('sign out asks first, then dispatches SignOutRequested', (
    tester,
  ) async {
    await pumpTab(tester, loadedProfile());

    await tester.scrollUntilVisible(find.text('Sign out'), 200);
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    verifyNever(() => authBloc.add(const SignOutRequested()));

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Sign out'),
      ),
    );
    await tester.pumpAndSettle();
    verify(() => authBloc.add(const SignOutRequested())).called(1);
  });

  testWidgets('cancelling the sign out dialog dispatches nothing', (
    tester,
  ) async {
    await pumpTab(tester, loadedProfile());

    await tester.scrollUntilVisible(find.text('Sign out'), 200);
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    verifyNever(() => authBloc.add(any()));
  });

  testWidgets('delete account opens the confirmation', (tester) async {
    registerGetItDeleteCubit();
    await pumpTab(tester, loadedProfile());

    await tester.scrollUntilVisible(find.text('Delete account'), 200);
    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();

    expect(find.text('Delete your account?'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
