import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:veloce/core/data/services/verification_sim.dart';
import 'package:veloce/core/domain/enums/auth_provider_kind.dart';
import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/domain/services/verification_provider.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/theme/app_theme.dart';
import 'package:veloce/core/widgets/app_messenger.dart';
import 'package:veloce/features/auth/domain/entities/auth_user.dart';
import 'package:veloce/features/auth/domain/usecases/complete_google_registration.dart';
import 'package:veloce/features/auth/domain/usecases/register_with_email.dart';
import 'package:veloce/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:veloce/features/auth/presentation/bloc/register_bloc.dart';
import 'package:veloce/features/auth/presentation/bloc/register_draft.dart';
import 'package:veloce/features/auth/presentation/pages/register_details_page.dart';
import 'package:veloce/features/auth/presentation/pages/register_role_page.dart';
import 'package:veloce/features/auth/presentation/pages/register_verify_page.dart';
import 'package:veloce/features/auth/presentation/widgets/register_flow_scope.dart';

import '../../domain/auth_fakes.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _MockRegisterBloc extends MockBloc<RegisterEvent, RegisterState>
    implements RegisterBloc {}

class _MockRegisterWithEmail extends Mock implements RegisterWithEmail {}

class _MockCompleteGoogle extends Mock implements CompleteGoogleRegistration {}

void main() {
  late AppMessenger messenger;
  AuthUser? receivedGoogleUser;

  setUp(() {
    messenger = AppMessenger();
    receivedGoogleUser = null;
    GetIt.instance
      ..registerSingleton<AppMessenger>(messenger)
      ..registerSingleton<Clock>(const FixedClock())
      ..registerFactoryParam<RegisterBloc, AuthUser?, void>((googleUser, _) {
        receivedGoogleUser = googleUser;
        return RegisterBloc(
          registerWithEmail: _MockRegisterWithEmail(),
          completeGoogle: _MockCompleteGoogle(),
          verification: VerificationSim(),
          clock: const FixedClock(),
          googleUser: googleUser,
        );
      });
  });

  tearDown(() => GetIt.instance.reset());

  Future<void> pumpFlow(WidgetTester tester, AuthState authState) async {
    final auth = _MockAuthBloc();
    when(() => auth.state).thenReturn(authState);
    whenListen(auth, const Stream<AuthState>.empty(), initialState: authState);
    final router = GoRouter(
      initialLocation: RouteNames.registerRole,
      routes: [
        ShellRoute(
          builder: (context, state, child) => RegisterFlowScope(child: child),
          routes: [
            GoRoute(
              path: RouteNames.registerRole,
              builder: (_, _) => const RegisterRolePage(),
            ),
            GoRoute(
              path: RouteNames.registerDetails,
              builder: (_, _) => const RegisterDetailsPage(),
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: auth,
        child: MaterialApp.router(
          theme: AppTheme.light,
          scaffoldMessengerKey: messenger.key,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('choosing a role opens the details step of the same bloc', (
    tester,
  ) async {
    await pumpFlow(tester, const AuthUnauthenticated());

    expect(find.text('How will you use Veloce?'), findsOneWidget);
    await tester.tap(find.text('Renter'));
    await tester.pumpAndSettle();

    expect(find.text('Renter details'), findsOneWidget);
    expect(find.text('Driving licence number'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(receivedGoogleUser, isNull);
  });

  testWidgets('Back on the details step returns to the role step', (
    tester,
  ) async {
    await pumpFlow(tester, const AuthUnauthenticated());
    await tester.tap(find.text('Car owner'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('How will you use Veloce?'), findsOneWidget);
  });

  testWidgets('a first Google sign-in gets the Google user, no email field', (
    tester,
  ) async {
    final google = anAuthUser(provider: AuthProviderKind.google);
    await pumpFlow(tester, AuthNeedsProfile(google));

    expect(receivedGoogleUser, google);
    await tester.tap(find.text('Car owner'));
    await tester.pumpAndSettle();

    expect(find.text('National ID number'), findsOneWidget);
    expect(find.text('Email'), findsNothing);
  });

  testWidgets('a new OTP code is shown in a SnackBar', (tester) async {
    final bloc = _MockRegisterBloc();
    const first = RegisterState(
      step: RegisterStep.otp,
      draft: RegisterDraft(phone: '0788123456'),
    );
    const second = RegisterState(
      step: RegisterStep.otp,
      draft: RegisterDraft(phone: '0788123456'),
      challenge: OtpChallenge(phone: '0788123456', code: '482913'),
    );
    when(() => bloc.state).thenReturn(first);
    whenListen(bloc, Stream.value(second), initialState: first);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        scaffoldMessengerKey: messenger.key,
        home: BlocProvider<RegisterBloc>.value(
          value: bloc,
          child: const RegisterVerifyPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('482913'), findsOneWidget);
  });
}
