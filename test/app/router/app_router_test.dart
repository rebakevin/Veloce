import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:veloce/app/router/app_router.dart';
import 'package:veloce/app/router/main_bar.dart';
import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/navigation/auth_redirect.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/theme/app_theme.dart';
import 'package:veloce/core/widgets/placeholder_links.dart';
import 'package:veloce/features/auth/domain/dev_route_catalog.dart';
import 'package:veloce/features/auth/presentation/pages/dev_routes_page.dart';

class _FakeSession implements AuthSession {
  _FakeSession(this.role);

  @override
  final UserRole? role;

  @override
  String? get currentUserId => role == null ? null : 'user';

  @override
  Stream<void> get changes => const Stream.empty();
}

/// Pages a signed-in user is redirected away from, so a signed-out session opens them.
bool _isAuthPage(String path) =>
    authRedirect(
      userId: 'user',
      role: requiredRoleFor(path) ?? UserRole.renter,
      location: path,
    ) !=
    null;

Future<GoRouter> _pumpApp(
  WidgetTester tester,
  UserRole? role, {
  String? initialLocation,
}) async {
  final router = createAppRouter(
    _FakeSession(role),
    initialLocation:
        initialLocation ??
        (role == UserRole.owner ? RouteNames.ownerHome : RouteNames.renterHome),
  );
  await tester.pumpWidget(
    MaterialApp.router(routerConfig: router, theme: AppTheme.light),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('both shells show the mock bottom bar and its bell and action', (
    tester,
  ) async {
    for (final (role, action, bellRoute) in [
      (UserRole.renter, 'Search cars', RouteNames.renterNotifications),
      (UserRole.owner, 'My cars', RouteNames.ownerNotifications),
    ]) {
      final router = await _pumpApp(tester, role);
      for (final tab in ['Home', 'My Activity', 'Profile']) {
        expect(
          find.descendant(of: find.byType(MainBar), matching: find.text(tab)),
          findsOneWidget,
          reason: '$role tab $tab',
        );
      }
      expect(find.byTooltip(action), findsOneWidget);

      await tester.tap(find.byTooltip('Notifications'));
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, bellRoute);
    }
  });

  testWidgets('every route opens and every link on it reaches a route', (
    tester,
  ) async {
    final probe = createAppRouter(_FakeSession(UserRole.owner));
    final entries = DevRouteCatalog.fromPatterns(
      DevRoutesPage.patterns(probe.configuration.routes),
    );
    expect(entries.length, greaterThan(55));

    final failures = <String>[];
    var tapped = 0;
    for (final entry in entries) {
      final role = _isAuthPage(entry.path)
          ? null
          : entry.role ?? UserRole.renter;
      final router = await _pumpApp(tester, role, initialLocation: entry.path);
      if (router.state.matchedLocation != entry.path) {
        failures.add('${entry.path} opened ${router.state.matchedLocation}');
        continue;
      }

      final linkCount = find
          .descendant(
            of: find.byType(PlaceholderLinks),
            matching: find.byType(ListTile),
          )
          .evaluate()
          .length;
      for (var i = 0; i < linkCount; i++) {
        router.go(entry.path);
        await tester.pumpAndSettle();
        final tile = find
            .descendant(
              of: find.byType(PlaceholderLinks),
              matching: find.byType(ListTile),
            )
            .at(i);
        final label = (tester.widget<ListTile>(tile).title! as Text).data;
        await tester.ensureVisible(tile);
        await tester.tap(tile);
        tapped++;
        await tester.pumpAndSettle();
        if (router.state.error != null) {
          failures.add('${entry.path} -> "$label" is not a route');
        }
      }
    }
    expect(failures, isEmpty);
    expect(tapped, greaterThan(50));
  });
}
