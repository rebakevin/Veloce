import '../domain/enums/user_role.dart';
import 'route_names.dart';

/// Decides where the router sends a user. Unverified emails are not redirected:
/// they may browse, and request/publish/pay check `EmailVerificationGate`.
String? authRedirect({
  required String? userId,
  required UserRole? role,
  required String location,
}) {
  final isAuthPage = _isAuthPage(location);

  if (RouteNames.isDevTool(location)) return null;

  if (userId == null) return isAuthPage ? null : RouteNames.welcome;

  // Signed in but the profile (role) is not known yet: registration or restore.
  // The account switcher signs another user in on its own pages and must stay.
  if (role == null) {
    if (location.startsWith(RouteNames.profileAccounts)) return null;
    return isAuthPage || location == RouteNames.verifyEmail
        ? null
        : RouteNames.splash;
  }

  final home = _homeFor(role);
  // The register flow ends on its own pages (welcome, then verify-email), and
  // a signed-in user may open it to add another account.
  if (location.startsWith('/register')) return null;
  if (isAuthPage) return home;
  final required = requiredRoleFor(location);
  if (required != null && required != role) return home;
  return null;
}

/// The only role allowed on [location], or null when any signed-in user is.
UserRole? requiredRoleFor(String location) {
  if (location.startsWith('/owner')) return UserRole.owner;
  if (location.startsWith('/renter')) return UserRole.renter;
  return null;
}

String _homeFor(UserRole role) => switch (role) {
  UserRole.renter => RouteNames.renterHome,
  UserRole.owner => RouteNames.ownerHome,
};

bool _isAuthPage(String location) =>
    location == RouteNames.splash ||
    location == RouteNames.welcome ||
    location == RouteNames.login ||
    location == RouteNames.forgotPassword ||
    location.startsWith('/register');
