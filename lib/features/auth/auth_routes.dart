import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'package:veloce/core/navigation/navigator_keys.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/widgets/placeholder_page.dart';

import 'presentation/pages/dev_login_page.dart';

/// Full-screen routes of the auth feature, opened above the tab bar.
List<RouteBase> authRoutes() => [
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.splash,
    builder: (context, state) => const PlaceholderPage(
      title: 'Splash',
      route: RouteNames.splash,
      phase: 1,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.welcome,
    builder: (context, state) => const PlaceholderPage(
      title: 'Welcome',
      route: RouteNames.welcome,
      phase: 1,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.login,
    builder: (context, state) => const PlaceholderPage(
      title: 'Log in',
      route: RouteNames.login,
      phase: 1,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.forgotPassword,
    builder: (context, state) => const PlaceholderPage(
      title: 'Forgot password',
      route: RouteNames.forgotPassword,
      phase: 1,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.registerRole,
    builder: (context, state) => const PlaceholderPage(
      title: 'Choose role',
      route: RouteNames.registerRole,
      phase: 1,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.registerDetails,
    builder: (context, state) => const PlaceholderPage(
      title: 'Your details',
      route: RouteNames.registerDetails,
      phase: 1,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.registerVerify,
    builder: (context, state) => const PlaceholderPage(
      title: 'Verify',
      route: RouteNames.registerVerify,
      phase: 1,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.registerWelcome,
    builder: (context, state) => const PlaceholderPage(
      title: 'Welcome to Veloce',
      route: RouteNames.registerWelcome,
      phase: 1,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.verifyEmail,
    builder: (context, state) => const PlaceholderPage(
      title: 'Verify your email',
      route: RouteNames.verifyEmail,
      phase: 1,
    ),
  ),
  if (kDebugMode)
    GoRoute(
      path: RouteNames.devLogin,
      builder: (context, state) => const DevLoginPage(),
    ),
];
