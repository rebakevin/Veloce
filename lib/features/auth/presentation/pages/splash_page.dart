import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:veloce/core/data/services/preferences_service.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/error_view.dart';

import '../auth_destination.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/brand_mark.dart';

/// First screen. Shows the brand while the session is restored, then leaves
/// for the destination [authDestination] picks.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SplashView(
      onboardingSeen: GetIt.instance<PreferencesService>().onboardingSeen,
    );
  }
}

class SplashView extends StatelessWidget {
  const SplashView({required this.onboardingSeen, super.key});

  final bool onboardingSeen;

  void _route(BuildContext context, AuthState state) {
    final destination = authDestination(state, onboardingSeen: onboardingSeen);
    if (destination != null) context.go(destination);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      // The state may already be known when the splash opens.
      listener: _route,
      builder: (context, state) {
        return switch (state) {
          AuthProfileFailed(:final message) => _SessionProblem(
            message: message,
          ),
          AuthNeedsProfile(needsRoleChoice: false) => const _SessionProblem(
            message:
                'Your registration did not finish. Try again, or sign out '
                'and start over.',
          ),
          _ => const _SplashBrand(),
        };
      },
    );
  }
}

class _SplashBrand extends StatelessWidget {
  const _SplashBrand();

  @override
  Widget build(BuildContext context) {
    return const AuthScaffold(
      child: Column(
        children: [
          SizedBox(height: AppSpacing.xl * 3),
          BrandMark(),
          SizedBox(height: AppSpacing.xl),
          CircularProgressIndicator(),
        ],
      ),
    );
  }
}

class _SessionProblem extends StatelessWidget {
  const _SessionProblem({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthBloc>();
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ErrorView(
                message: message,
                onRetry: () => auth.add(const AuthProfileRefreshed()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: TextButton(
                onPressed: () => auth.add(const SignOutRequested()),
                child: const Text('Sign out', style: AppTextStyles.button),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
