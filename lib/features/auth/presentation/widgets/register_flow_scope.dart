import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:veloce/core/navigation/route_names.dart';

import '../../domain/entities/auth_user.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/register_bloc.dart';

/// Owns the single [RegisterBloc] of the sign-up flow and moves between the
/// register routes when its step changes. Mount it as the builder of a
/// `ShellRoute` that wraps `/register/role`, `/register/details`,
/// `/register/verify` and `/register/welcome`, so the draft survives every
/// step.
///
/// The Google user comes from [AuthBloc] (`AuthNeedsProfile` with a Google
/// account); email sign-ups get `null`. If a Google user appears after the
/// flow opened, the bloc is replaced by a Google one.
class RegisterFlowScope extends StatefulWidget {
  const RegisterFlowScope({required this.child, super.key});

  final Widget child;

  /// The route that shows [step], or `null` while the step has no page of its
  /// own (the final write runs on the page that started it).
  static String? routeFor(RegisterStep step) => switch (step) {
    RegisterStep.role => RouteNames.registerRole,
    RegisterStep.details => RouteNames.registerDetails,
    RegisterStep.otp => RouteNames.registerVerify,
    RegisterStep.submitting => null,
    RegisterStep.done => RouteNames.registerWelcome,
  };

  @override
  State<RegisterFlowScope> createState() => _RegisterFlowScopeState();
}

class _RegisterFlowScopeState extends State<RegisterFlowScope> {
  late final ValueNotifier<RegisterBloc> _bloc = ValueNotifier(
    _createBloc(_googleUserOf(context.read<AuthBloc>().state)),
  );

  static AuthUser? _googleUserOf(AuthState state) => switch (state) {
    AuthNeedsProfile(:final user, :final needsRoleChoice)
        when needsRoleChoice =>
      user,
    _ => null,
  };

  static RegisterBloc _createBloc(AuthUser? googleUser) =>
      GetIt.instance<RegisterBloc>(param1: googleUser);

  @override
  void initState() {
    super.initState();
    // A deep link to a later step lands on the step the bloc is really at.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final target = RegisterFlowScope.routeFor(_bloc.value.state.step);
      final here = GoRouterState.of(context).uri.path;
      if (target != null && target != here) context.go(target);
    });
  }

  @override
  void dispose() {
    unawaited(_bloc.value.close());
    _bloc.dispose();
    super.dispose();
  }

  /// A Google account signed in while an email sign-up was open ("Sign up with
  /// Google" on the role step): restart the flow as a Google registration.
  void _onAuth(BuildContext context, AuthState state) {
    final googleUser = _googleUserOf(state);
    if (googleUser == null || _bloc.value.state.isGoogle) return;
    final previous = _bloc.value;
    _bloc.value = _createBloc(googleUser);
    unawaited(previous.close());
  }

  void _onStep(BuildContext context, RegisterState state) {
    final target = RegisterFlowScope.routeFor(state.step);
    if (target != null) context.go(target);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: _onAuth,
      child: ValueListenableBuilder<RegisterBloc>(
        valueListenable: _bloc,
        builder: (context, bloc, child) => BlocProvider.value(
          value: bloc,
          child: BlocListener<RegisterBloc, RegisterState>(
            listenWhen: (previous, current) => previous.step != current.step,
            listener: _onStep,
            child: child,
          ),
        ),
        child: widget.child,
      ),
    );
  }
}
