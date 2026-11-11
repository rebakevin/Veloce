import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/error_view.dart';
import 'package:veloce/core/widgets/loading_view.dart';

import '../auth_destination.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/register_bloc.dart';
import '../widgets/auth_scaffold.dart';

/// Step 4: the account exists. Asks [AuthBloc] to read the new profile, then
/// continues to the verify-email page (email users) or Home (Google users).
/// Needs the flow's [RegisterBloc] and the app's [AuthBloc].
class RegisterWelcomePage extends StatefulWidget {
  const RegisterWelcomePage({super.key});

  @override
  State<RegisterWelcomePage> createState() => _RegisterWelcomePageState();
}

class _RegisterWelcomePageState extends State<RegisterWelcomePage> {
  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(const AuthProfileRefreshed());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) => switch (state) {
        AuthAuthenticated(:final role, :final account) => _Done(
          name: account.name,
          emailSent: context.read<RegisterBloc>().state.verificationEmailSent,
          onContinue: () => context.go(
            context.read<RegisterBloc>().state.isGoogle
                ? homeRouteFor(role)
                : RouteNames.verifyEmail,
          ),
        ),
        AuthProfileFailed(:final message) => Scaffold(
          body: SafeArea(
            child: ErrorView(
              message: message,
              onRetry: () =>
                  context.read<AuthBloc>().add(const AuthProfileRefreshed()),
            ),
          ),
        ),
        _ => const Scaffold(body: LoadingView()),
      },
    );
  }
}

class _Done extends StatelessWidget {
  const _Done({
    required this.name,
    required this.emailSent,
    required this.onContinue,
  });

  final String name;
  final bool emailSent;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AuthScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xl),
          Icon(Icons.check_circle_outline, size: 80, color: colors.brand),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Welcome to Veloce, $name',
            style: AppTextStyles.title,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            emailSent
                ? 'Your account is ready. We sent a link to confirm your '
                      'email.'
                : 'Your account is ready.',
            style: AppTextStyles.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(onPressed: onContinue, child: const Text('Continue')),
        ],
      ),
    );
  }
}
