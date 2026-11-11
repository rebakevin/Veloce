import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'package:veloce/core/navigation/navigator_keys.dart';
import 'package:veloce/core/navigation/route_names.dart';

import 'presentation/pages/dev_login_page.dart';
import 'presentation/pages/dev_routes_page.dart';
import 'presentation/pages/forgot_password_page.dart';
import 'presentation/pages/login_page.dart';
import 'presentation/pages/register_details_page.dart';
import 'presentation/pages/register_role_page.dart';
import 'presentation/pages/register_verify_page.dart';
import 'presentation/pages/register_welcome_page.dart';
import 'presentation/pages/splash_page.dart';
import 'presentation/pages/verify_email_page.dart';
import 'presentation/pages/welcome_page.dart';
import 'presentation/widgets/register_flow_scope.dart';

/// Full-screen routes of the auth feature, opened above the tab bar.
List<RouteBase> authRoutes() => [
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.splash,
    builder: (context, state) => const SplashPage(),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.welcome,
    builder: (context, state) => const WelcomePage(),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.login,
    builder: (context, state) => const LoginPage(),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.forgotPassword,
    builder: (context, state) => const ForgotPasswordPage(),
  ),
  // One RegisterBloc spans the four register steps.
  ShellRoute(
    parentNavigatorKey: rootNavigatorKey,
    builder: (context, state, child) => RegisterFlowScope(child: child),
    routes: [
      GoRoute(
        path: RouteNames.registerRole,
        builder: (context, state) => const RegisterRolePage(),
      ),
      GoRoute(
        path: RouteNames.registerDetails,
        builder: (context, state) => const RegisterDetailsPage(),
      ),
      GoRoute(
        path: RouteNames.registerVerify,
        builder: (context, state) => const RegisterVerifyPage(),
      ),
      GoRoute(
        path: RouteNames.registerWelcome,
        builder: (context, state) => const RegisterWelcomePage(),
      ),
    ],
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.verifyEmail,
    builder: (context, state) => const VerifyEmailPage(),
  ),
  if (kDebugMode) ...[
    GoRoute(
      path: RouteNames.devLogin,
      builder: (context, state) => const DevLoginPage(),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: RouteNames.devRoutes,
      builder: (context, state) => const DevRoutesPage(),
    ),
  ],
];
