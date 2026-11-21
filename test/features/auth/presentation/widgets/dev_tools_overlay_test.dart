import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:veloce/core/data/services/momo_gateway_sim.dart';
import 'package:veloce/core/data/services/verification_sim.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/core/navigation/navigator_keys.dart';
import 'package:veloce/core/widgets/app_messenger.dart';
import 'package:veloce/features/auth/data/dev_sign_in.dart';
import 'package:veloce/features/auth/domain/dev_account.dart';
import 'package:veloce/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:veloce/features/auth/presentation/widgets/dev_tools_overlay.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _MockDevSignIn extends Mock implements DevSignIn {}

void main() {
  final getIt = GetIt.instance;
  final button = find.byIcon(Icons.developer_mode);

  late _MockDevSignIn signIn;

  setUpAll(() => registerFallbackValue(DevAccounts.all.first));

  setUp(() {
    signIn = _MockDevSignIn();
    getIt
      ..registerSingleton<DevSignIn>(signIn)
      ..registerSingleton<MomoGatewaySim>(MomoGatewaySim())
      ..registerSingleton<VerificationSim>(VerificationSim())
      ..registerSingleton<AppMessenger>(AppMessenger());
  });

  tearDown(getIt.reset);

  Future<void> pumpApp(WidgetTester tester) async {
    final auth = _MockAuthBloc();
    when(() => auth.state).thenReturn(const AuthUnauthenticated());
    final router = GoRouter(
      navigatorKey: rootNavigatorKey,
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('A page')),
        ),
        GoRoute(
          path: '/splash',
          builder: (_, _) => const Scaffold(body: Text('Splash')),
        ),
      ],
    );
    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: auth,
        child: MaterialApp.router(
          routerConfig: router,
          builder: (context, child) =>
              DevToolsOverlay(router: router, child: child!),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the dev button floats above the page', (tester) async {
    await pumpApp(tester);

    expect(find.text('A page'), findsOneWidget);
    expect(button, findsOneWidget);
  });

  testWidgets('tapping the button opens the dev panel', (tester) async {
    await pumpApp(tester);

    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('Dev tools'), findsWidgets);
    expect(find.text('Sign in as'), findsOneWidget);
    expect(find.text('MoMo payments succeed'), findsOneWidget);
    expect(find.text('Verification succeeds'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Browse all routes'),
      200,
      scrollable: find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('Browse all routes'), findsOneWidget);
  });

  testWidgets('the payment switch changes the simulation', (tester) async {
    await pumpApp(tester);
    await tester.tap(button);
    await tester.pumpAndSettle();

    await tester.tap(find.text('MoMo payments succeed'));
    await tester.pumpAndSettle();

    expect(getIt<MomoGatewaySim>().shouldSucceed, isFalse);
  });

  testWidgets('the button can be dragged out of the way', (tester) async {
    await pumpApp(tester);
    final before = tester.getTopLeft(button);

    await tester.drag(button, const Offset(-120, -200));
    await tester.pump();

    expect(tester.getTopLeft(button), isNot(before));
  });

  testWidgets('choosing an account closes the panel, then signs in', (
    tester,
  ) async {
    when(() => signIn.signIn(any()))
        .thenAnswer((_) async => const Result.success(null));
    await pumpApp(tester);
    await tester.tap(button);
    await tester.pumpAndSettle();

    await tester.tap(find.text(DevAccounts.all.first.name));
    await tester.pumpAndSettle();

    verify(() => signIn.signIn(DevAccounts.all.first)).called(1);
    expect(find.text('Sign in as'), findsNothing);
    expect(find.text('Splash'), findsOneWidget);
    expect(button, findsOneWidget);
  });

  testWidgets('the button steps aside while the panel is open', (tester) async {
    await pumpApp(tester);

    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(button, findsNothing);
  });
}
