import '../domain/enums/user_role.dart';
import 'route_names.dart';

/// Decides where the router sends a user. Phase 1 completes this (unverified
/// email gate); the structure stays.
String? authRedirect({
  required String? userId,
  required UserRole? role,
  required String location,
}) {
  final isAuthPage = _isAuthPage(location);

  if (location == RouteNames.devLogin) return null;

  if (userId == null) return isAuthPage ? null : RouteNames.welcome;

  // Signed in but the profile (role) is not known yet: registration or restore.
  if (role == null) {
    return isAuthPage || location == RouteNames.verifyEmail
        ? null
        : RouteNames.splash;
  }

  final home = _homeFor(role);
  if (isAuthPage) return home;
  if (location.startsWith('/owner') && role != UserRole.owner) return home;
  if (location.startsWith('/renter') && role != UserRole.renter) return home;
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
