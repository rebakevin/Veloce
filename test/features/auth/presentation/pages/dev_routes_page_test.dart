import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:veloce/features/auth/presentation/pages/dev_routes_page.dart';

import '../../../../support/builders.dart';
import '../../domain/auth_fakes.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

void main() {
  Future<void> pumpAs(WidgetTester tester, UserRole role) async {
    final auth = _MockAuthBloc();
    when(() => auth.state).thenReturn(
      AuthAuthenticated(
        user: anAuthUser(),
        account: aUser(role: role),
      ),
    );
    final router = GoRouter(
      initialLocation: '/dev/routes',
      routes: [
        GoRoute(path: '/dev/routes', builder: (_, _) => const DevRoutesPage()),
        GoRoute(path: '/renter/home', builder: (_, _) => const SizedBox()),
        GoRoute(path: '/owner/home', builder: (_, _) => const SizedBox()),
      ],
    );
    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: auth,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
  }

  bool enabled(WidgetTester tester, String route) =>
      tester.widget<ListTile>(find.widgetWithText(ListTile, route)).enabled;

  testWidgets('a renter can open renter routes but not owner routes', (
    tester,
  ) async {
    await pumpAs(tester, UserRole.renter);

    expect(enabled(tester, '/renter/home'), isTrue);
    expect(enabled(tester, '/owner/home'), isFalse);
  });

  testWidgets('an owner can open owner routes but not renter routes', (
    tester,
  ) async {
    await pumpAs(tester, UserRole.owner);

    expect(enabled(tester, '/owner/home'), isTrue);
    expect(enabled(tester, '/renter/home'), isFalse);
  });
}
