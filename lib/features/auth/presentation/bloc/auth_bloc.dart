import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:veloce/core/domain/entities/user_account.dart';
import 'package:veloce/core/domain/enums/auth_provider_kind.dart';
import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/error/result.dart';

import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/registration_store.dart';
import '../../domain/usecases/observe_auth_state.dart';
import '../../domain/usecases/reload_auth_user.dart';
import '../../domain/usecases/sign_out.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// App-wide session state. Follows the Firebase user, loads the `users/{uid}`
/// profile for the role and restores the session after a restart because the
/// first stream event carries the persisted user.
///
/// [clearCaches] runs on every sign-out so no cached profile, vehicle or
/// booking outlives the session (wire it to the lookups in DI).
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required this._observe,
    required this._profiles,
    required this._signOut,
    required this._reloadUser,
    required this._clearCaches,
  }) : super(const AuthUnknown()) {
    on<AuthStarted>(_onStarted);
    on<AuthUserChanged>(_onUserChanged);
    on<AuthProfileRefreshed>(_onProfileRefreshed);
    on<EmailVerificationRefreshed>(_onVerificationRefreshed);
    on<SignOutRequested>(_onSignOutRequested);
  }

  final ObserveAuthState _observe;
  final RegistrationStore _profiles;
  final SignOut _signOut;
  final ReloadAuthUser _reloadUser;
  final void Function() _clearCaches;

  StreamSubscription<AuthUser?>? _subscription;

  /// Bumped for every change so a slow profile read never overwrites a newer
  /// state (for example a sign-out that happened while it was loading).
  int _generation = 0;

  void _onStarted(AuthStarted event, Emitter<AuthState> emit) {
    _subscription ??= _observe().listen(
      (user) => add(AuthUserChanged(user)),
      onError: (Object _) => add(const AuthUserChanged(null)),
    );
  }

  Future<void> _onUserChanged(
    AuthUserChanged event,
    Emitter<AuthState> emit,
  ) async {
    final user = event.user;
    final generation = ++_generation;
    if (user == null) {
      _clearCaches();
      emit(const AuthUnauthenticated());
      return;
    }
    // Token refreshes and the verified flag change the user but not the
    // profile, so keep the loaded profile instead of reading it again.
    final current = state;
    if (current is AuthAuthenticated && current.user.uid == user.uid) {
      emit(AuthAuthenticated(user: user, account: current.account));
      return;
    }
    await _loadProfile(user, generation, emit);
  }

  Future<void> _onProfileRefreshed(
    AuthProfileRefreshed event,
    Emitter<AuthState> emit,
  ) async {
    final user = state.user;
    if (user == null) return;
    await _loadProfile(user, ++_generation, emit);
  }

  Future<void> _loadProfile(
    AuthUser user,
    int generation,
    Emitter<AuthState> emit,
  ) async {
    final found = await _profiles.findProfile(user.uid);
    if (isClosed || generation != _generation) return;
    emit(switch (found) {
      Success(:final value) when value != null => AuthAuthenticated(
        user: user,
        account: value,
      ),
      Success() => AuthNeedsProfile(user),
      Failure(:final failure) => AuthProfileFailed(user, failure.message),
    });
  }

  Future<void> _onVerificationRefreshed(
    EmailVerificationRefreshed event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _reloadUser();
    if (isClosed) return;
    if (result case Success(:final value)) {
      final current = state;
      if (current is AuthAuthenticated && current.user.uid == value.uid) {
        emit(AuthAuthenticated(user: value, account: current.account));
      } else if (current is AuthNeedsProfile && current.user.uid == value.uid) {
        emit(AuthNeedsProfile(value));
      }
    }
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _signOut();
    if (isClosed || result is Failure) return;
    _generation++;
    _clearCaches();
    emit(const AuthUnauthenticated());
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
