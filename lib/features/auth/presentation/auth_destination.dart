import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/navigation/route_names.dart';

import 'bloc/auth_bloc.dart';

/// Home tab of [role].
String homeRouteFor(UserRole role) => switch (role) {
  UserRole.renter => RouteNames.renterHome,
  UserRole.owner => RouteNames.ownerHome,
};

/// Where the app goes once the session state is known, or `null` when the
/// splash must stay (still loading, or a state that needs the user's choice:
/// profile read failed, or an email registration that never finished).
///
/// Unverified email users still go Home: they may browse, and only requests,
/// publishing and payment ask for a verified address.
String? authDestination(AuthState state, {required bool onboardingSeen}) =>
    switch (state) {
      AuthUnknown() => null,
      AuthUnauthenticated() =>
        onboardingSeen ? RouteNames.login : RouteNames.welcome,
      AuthAuthenticated(:final role) => homeRouteFor(role),
      AuthNeedsProfile(:final needsRoleChoice) =>
        needsRoleChoice ? RouteNames.registerRole : null,
      AuthProfileFailed() => null,
    };
