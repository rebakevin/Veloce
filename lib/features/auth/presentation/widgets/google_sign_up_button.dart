import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/widgets/app_messenger.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/login_bloc.dart';
import 'google_button.dart';

/// Google sign-in / sign-up on the welcome page and the first register step.
/// `SignInWithGoogle` covers both cases: a returning account just signs in and
/// is sent on to its home, a new one continues in the Google registration flow
/// (role, then documents; no email or password).
class GoogleSignUpButton extends StatelessWidget {
  const GoogleSignUpButton({super.key, this.label = 'Sign up with Google'});

  final String label;

  Future<void> _onState(BuildContext context, LoginState state) async {
    switch (state.status) {
      case LoginStatus.failure:
        GetIt.instance<AppMessenger>().error(
          state.message ?? 'Could not sign in with Google. Please try again.',
        );
      case LoginStatus.success:
        // A returning user: the splash sends them to the right home.
        context.go(RouteNames.splash);
      case LoginStatus.needsRegistration:
        await _openGoogleRegistration(context);
      case LoginStatus.idle || LoginStatus.invalid || LoginStatus.submitting:
        break;
    }
  }

  /// The register flow reads the Google user from [AuthBloc], so wait until it
  /// has loaded (and found no profile). On the role step this is the same
  /// location, and `RegisterFlowScope` restarts the flow as a Google one.
  Future<void> _openGoogleRegistration(BuildContext context) async {
    final auth = context.read<AuthBloc>();
    if (auth.state is! AuthNeedsProfile) {
      await auth.stream.firstWhere((state) => state is AuthNeedsProfile);
    }
    if (!context.mounted) return;
    context.go(RouteNames.registerRole);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.instance<LoginBloc>(),
      child: BlocConsumer<LoginBloc, LoginState>(
        listener: _onState,
        builder: (context, state) => GoogleButton(
          label: label,
          isLoading: state.isSubmitting,
          onPressed: () =>
              context.read<LoginBloc>().add(const LoginGoogleRequested()),
        ),
      ),
    );
  }
}
