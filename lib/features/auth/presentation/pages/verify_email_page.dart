import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/app_messenger.dart';
import 'package:veloce/core/widgets/primary_button.dart';

import '../auth_destination.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/verify_email_cubit.dart';
import '../widgets/auth_scaffold.dart';

class VerifyEmailPage extends StatelessWidget {
  const VerifyEmailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.instance<VerifyEmailCubit>(),
      child: const VerifyEmailView(),
    );
  }
}

/// Pending page after sign-up. Needs a [VerifyEmailCubit] and an [AuthBloc].
class VerifyEmailView extends StatelessWidget {
  const VerifyEmailView({super.key});

  void _onState(BuildContext context, VerifyEmailState state) {
    final messenger = GetIt.instance<AppMessenger>();
    switch (state.status) {
      case VerifyEmailStatus.verified:
        final auth = context.read<AuthBloc>()
          ..add(const EmailVerificationRefreshed());
        messenger.success('Your email is verified.');
        _goHome(context, auth.state);
      case VerifyEmailStatus.resent:
        messenger.success('We sent you a new verification email.');
      case VerifyEmailStatus.notVerifiedYet:
        messenger.error('Not verified yet. Open the link in your email first.');
      case VerifyEmailStatus.failure:
        messenger.error(state.message ?? 'Something went wrong. Try again.');
      case VerifyEmailStatus.idle ||
          VerifyEmailStatus.resending ||
          VerifyEmailStatus.checking:
        break;
    }
  }

  void _goHome(BuildContext context, AuthState auth) {
    context.go(switch (auth) {
      AuthAuthenticated(:final role) => homeRouteFor(role),
      _ => RouteNames.splash,
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final email = context.select((AuthBloc bloc) => bloc.state.user?.email);
    return AuthScaffold(
      title: 'Verify your email',
      child: BlocConsumer<VerifyEmailCubit, VerifyEmailState>(
        listener: _onState,
        builder: (context, state) {
          final cubit = context.read<VerifyEmailCubit>();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.lg),
              Icon(
                Icons.mark_email_unread_outlined,
                size: 64,
                color: colors.brand,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                email == null
                    ? 'We sent you a verification link.'
                    : 'We sent a verification link to $email.',
                style: AppTextStyles.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'You can browse cars now. Requesting a booking, listing a car '
                'and paying need a verified email.',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: "I've verified my email",
                isLoading: state.status == VerifyEmailStatus.checking,
                onPressed: state.isBusy ? null : cubit.checkVerified,
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                onPressed: state.isBusy ? null : cubit.resend,
                child: state.status == VerifyEmailStatus.resending
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Text('Resend email'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: () =>
                    _goHome(context, context.read<AuthBloc>().state),
                child: const Text('Do this later'),
              ),
              TextButton(
                onPressed: () =>
                    context.read<AuthBloc>().add(const SignOutRequested()),
                child: const Text('Sign out'),
              ),
            ],
          );
        },
      ),
    );
  }
}
