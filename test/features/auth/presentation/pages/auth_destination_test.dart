import 'package:flutter_test/flutter_test.dart';

import 'package:veloce/core/domain/enums/auth_provider_kind.dart';
import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/features/auth/presentation/auth_destination.dart';
import 'package:veloce/features/auth/presentation/bloc/auth_bloc.dart';

import '../../../../support/builders.dart';
import '../../domain/auth_fakes.dart';

void main() {
  String? destination(AuthState state, {bool seen = false}) =>
      authDestination(state, onboardingSeen: seen);

  test('stays on the splash while the session is unknown', () {
    expect(destination(const AuthUnknown()), isNull);
  });

  test('signed-out users see onboarding first, then the login', () {
    expect(destination(const AuthUnauthenticated()), RouteNames.welcome);
    expect(
      destination(const AuthUnauthenticated(), seen: true),
      RouteNames.login,
    );
  });

  test('a renter goes to the renter home', () {
    final state = AuthAuthenticated(user: anAuthUser(), account: aUser());
    expect(destination(state), RouteNames.renterHome);
  });

  test('an owner goes to the owner home, even with an unverified email', () {
    final state = AuthAuthenticated(
      user: anAuthUser(),
      account: aUser(role: UserRole.owner),
    );
    expect(destination(state), RouteNames.ownerHome);
  });

  test('a Google user without a profile goes to role choice', () {
    final state = AuthNeedsProfile(
      anAuthUser(provider: AuthProviderKind.google),
    );
    expect(destination(state), RouteNames.registerRole);
  });

  test('an unfinished email registration stays on the splash', () {
    expect(destination(AuthNeedsProfile(anAuthUser())), isNull);
  });

  test('a failed profile read stays on the splash for Retry', () {
    expect(destination(AuthProfileFailed(anAuthUser(), 'Offline')), isNull);
  });
}
