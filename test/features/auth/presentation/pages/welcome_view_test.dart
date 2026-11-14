import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:veloce/core/theme/app_theme.dart';
import 'package:veloce/features/auth/presentation/bloc/login_bloc.dart';
import 'package:veloce/features/auth/presentation/pages/welcome_page.dart';
import 'package:veloce/features/auth/presentation/widgets/page_index_cubit.dart';

class _MockLoginBloc extends MockBloc<LoginEvent, LoginState>
    implements LoginBloc {}

void main() {
  setUp(() {
    final login = _MockLoginBloc();
    when(() => login.state).thenReturn(const LoginState());
    GetIt.instance.registerFactory<LoginBloc>(() => login);
  });
  tearDown(() => GetIt.instance.reset());

  Future<void> pumpWelcome(WidgetTester tester, Size size) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BlocProvider(
          create: (_) => PageIndexCubit(),
          child: WelcomeView(markOnboardingSeen: () async {}),
        ),
      ),
    );
  }

  testWidgets('in landscape the slide and the buttons are both visible', (
    tester,
  ) async {
    await pumpWelcome(tester, const Size(800, 360));

    expect(find.text('Find the right car'), findsOneWidget);
    expect(find.text('Create an account'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('in portrait the slide sits above the buttons', (tester) async {
    await pumpWelcome(tester, const Size(400, 800));

    expect(find.text('Find the right car'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Find the right car')).dy,
      lessThan(tester.getTopLeft(find.text('Create an account')).dy),
    );
    expect(tester.takeException(), isNull);
  });
}
