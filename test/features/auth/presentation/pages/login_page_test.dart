import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:veloce/core/theme/app_theme.dart';
import 'package:veloce/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:veloce/features/auth/presentation/bloc/login_bloc.dart';
import 'package:veloce/features/auth/presentation/pages/login_page.dart';

class _MockLoginBloc extends MockBloc<LoginEvent, LoginState>
    implements LoginBloc {}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

void main() {
  late _MockLoginBloc login;

  setUpAll(() => registerFallbackValue(const LoginGoogleRequested()));

  setUp(() {
    login = _MockLoginBloc();
    final auth = _MockAuthBloc();
    when(() => auth.state).thenReturn(const AuthUnauthenticated());
    _auth = auth;
  });

  Future<void> pumpLogin(WidgetTester tester, LoginState state) async {
    when(() => login.state).thenReturn(state);
    whenListen(login, const Stream<LoginState>.empty(), initialState: state);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<LoginBloc>.value(value: login),
            BlocProvider<AuthBloc>.value(value: _auth),
          ],
          child: const LoginView(),
        ),
      ),
    );
  }

  testWidgets('shows the validation errors under the fields', (tester) async {
    await pumpLogin(
      tester,
      const LoginState(
        status: LoginStatus.invalid,
        emailError: 'Enter your email address.',
        passwordError: 'Enter your password.',
      ),
    );

    expect(find.text('Enter your email address.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
  });

  testWidgets('Log in sends the typed credentials to the bloc', (tester) async {
    await pumpLogin(tester, const LoginState());

    await tester.enterText(find.byType(TextField).at(0), 'aline@example.rw');
    await tester.enterText(find.byType(TextField).at(1), 'secret123');
    await tester.ensureVisible(find.text('Log in'));
    await tester.tap(find.text('Log in'));

    verify(
      () => login.add(
        const LoginSubmitted(email: 'aline@example.rw', password: 'secret123'),
      ),
    ).called(1);
  });

  testWidgets('a blank submit still goes to the bloc, which blocks it', (
    tester,
  ) async {
    await pumpLogin(tester, const LoginState());

    await tester.ensureVisible(find.text('Log in'));
    await tester.tap(find.text('Log in'));

    verify(() => login.add(const LoginSubmitted(email: '', password: '')))
        .called(1);
  });

  testWidgets('the Google button asks the bloc for a Google sign-in', (
    tester,
  ) async {
    await pumpLogin(tester, const LoginState());

    await tester.ensureVisible(find.text('Continue with Google'));
    await tester.tap(find.text('Continue with Google'));

    verify(() => login.add(const LoginGoogleRequested())).called(1);
  });

  testWidgets('the password toggle shows and hides the text', (tester) async {
    await pumpLogin(tester, const LoginState());
    TextField password() =>
        tester.widget<TextField>(find.byType(TextField).at(1));

    expect(password().obscureText, isTrue);
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(password().obscureText, isFalse);
  });

  testWidgets('buttons are disabled while a request runs', (tester) async {
    await pumpLogin(
      tester,
      const LoginState(
        status: LoginStatus.submitting,
        method: LoginMethod.email,
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final google = tester.widget<OutlinedButton>(
      find.ancestor(
        of: find.text('Continue with Google'),
        matching: find.byWidgetPredicate((w) => w is OutlinedButton),
      ),
    );
    expect(google.onPressed, isNull);
  });
}

late _MockAuthBloc _auth;
