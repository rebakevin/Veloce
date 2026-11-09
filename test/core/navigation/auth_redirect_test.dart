import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/navigation/auth_redirect.dart';
import 'package:veloce/core/navigation/route_names.dart';

void main() {
  test('signed-out users are sent to welcome, except on auth pages', () {
    expect(
      authRedirect(userId: null, role: null, location: RouteNames.renterHome),
      RouteNames.welcome,
    );
    expect(
      authRedirect(userId: null, role: null, location: RouteNames.login),
      isNull,
    );
    expect(
      authRedirect(userId: null, role: null, location: '/register/details'),
      isNull,
    );
  });

  test('signed-in users leave auth pages for their own home', () {
    expect(
      authRedirect(
        userId: 'u',
        role: UserRole.owner,
        location: RouteNames.splash,
      ),
      RouteNames.ownerHome,
    );
    expect(
      authRedirect(
        userId: 'u',
        role: UserRole.renter,
        location: RouteNames.login,
      ),
      RouteNames.renterHome,
    );
  });

  test('each role stays inside its own shell', () {
    expect(
      authRedirect(
        userId: 'u',
        role: UserRole.renter,
        location: RouteNames.ownerCars,
      ),
      RouteNames.renterHome,
    );
    expect(
      authRedirect(
        userId: 'u',
        role: UserRole.owner,
        location: RouteNames.renterHome,
      ),
      RouteNames.ownerHome,
    );
    expect(
      authRedirect(
        userId: 'u',
        role: UserRole.owner,
        location: RouteNames.booking('b1'),
      ),
      isNull,
    );
  });

  test('a signed-in user without a profile waits on the splash', () {
    expect(
      authRedirect(userId: 'u', role: null, location: RouteNames.renterHome),
      RouteNames.splash,
    );
    expect(
      authRedirect(userId: 'u', role: null, location: RouteNames.registerRole),
      isNull,
    );
  });

  test('dev login is always reachable', () {
    expect(
      authRedirect(userId: null, role: null, location: RouteNames.devLogin),
      isNull,
    );
  });
}
