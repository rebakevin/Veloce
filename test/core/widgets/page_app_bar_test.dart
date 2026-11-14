import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:veloce/core/navigation/navigator_keys.dart';
import 'package:veloce/core/widgets/page_app_bar.dart';

Widget _app(GoRouter router) => MaterialApp.router(routerConfig: router);

GoRouter _router() => GoRouter(
  navigatorKey: rootNavigatorKey,
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => Scaffold(
        appBar: const PageAppBar(title: 'Home'),
        body: TextButton(
          onPressed: () => context.push('/direct'),
          child: const Text('open direct'),
        ),
      ),
    ),
    GoRoute(
      path: '/direct',
      builder: (context, state) =>
          const Scaffold(appBar: PageAppBar(title: 'Direct')),
    ),
    ShellRoute(
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state, child) => child,
      routes: [
        GoRoute(
          path: '/in-shell',
          builder: (context, state) =>
              const Scaffold(appBar: PageAppBar(title: 'In shell')),
        ),
      ],
    ),
  ],
);

void main() {
  testWidgets('a root page with nowhere to go back has no back button', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_router()));

    expect(find.text('Home'), findsOneWidget);
    expect(find.byTooltip('Back'), findsNothing);
  });

  testWidgets('a pushed page shows a back button that returns', (tester) async {
    await tester.pumpWidget(_app(_router()));
    await tester.tap(find.text('open direct'));
    await tester.pumpAndSettle();

    expect(find.text('Direct'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('the first page inside a ShellRoute still gets a back button', (
    tester,
  ) async {
    final router = _router();
    await tester.pumpWidget(_app(router));
    unawaited(router.push('/in-shell'));
    await tester.pumpAndSettle();

    expect(find.text('In shell'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('In shell'), findsNothing);
    expect(find.text('Home'), findsOneWidget);
  });
}
