import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:veloce/core/navigation/route_names.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/register_bloc.dart';

/// Owns the single [RegisterBloc] of the sign-up flow and moves between the
/// register routes when its step changes. Mount it as the builder of a
/// `ShellRoute` that wraps `/register/role`, `/register/details`,
/// `/register/verify` and `/register/welcome`, so the draft survives every
/// step.
///
/// The Google user is read once, when the flow opens, from [AuthBloc]
/// (`AuthNeedsProfile` with a Google account); email sign-ups get `null`.
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
  late final RegisterBloc _bloc = GetIt.instance<RegisterBloc>(
    param1: switch (context.read<AuthBloc>().state) {
      AuthNeedsProfile(:final user, :final needsRoleChoice)
          when needsRoleChoice =>
        user,
      _ => null,
    },
  );

  @override
  void initState() {
    super.initState();
    // A deep link to a later step lands on the step the bloc is really at.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final target = RegisterFlowScope.routeFor(_bloc.state.step);
      final here = GoRouterState.of(context).uri.path;
      if (target != null && target != here) context.go(target);
    });
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  void _onStep(BuildContext context, RegisterState state) {
    final target = RegisterFlowScope.routeFor(state.step);
    if (target != null) context.go(target);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocListener<RegisterBloc, RegisterState>(
        listenWhen: (previous, current) => previous.step != current.step,
        listener: _onStep,
        child: widget.child,
      ),
    );
  }
}
