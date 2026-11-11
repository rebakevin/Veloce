import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:veloce/core/layout/responsive.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';

import '../bloc/profile_bloc.dart';
import '../widgets/profile_loaded_builder.dart';

/// `/profile/licence/verify` (step 3 of 3): progress and result of the
/// simulated check started by the change form. Reads the same [ProfileBloc],
/// which remembers the submission, so Retry needs no form data.
class LicenceVerifyPage extends StatelessWidget {
  const LicenceVerifyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify licence')),
      body: ProfileLoadedBuilder(
        builder: (context, state) {
          final action = state.action;
          final isLicence = action.kind == ProfileActionKind.licence;
          return Center(
            child: SingleChildScrollView(
              padding: Responsive.pagePadding(context)
                  .copyWith(top: AppSpacing.xl, bottom: AppSpacing.xl),
              child: switch (isLicence ? action.status : null) {
                ProfileActionStatus.submitting => const _Progress(),
                ProfileActionStatus.success => const _Success(),
                ProfileActionStatus.verificationFailed ||
                ProfileActionStatus.failure ||
                ProfileActionStatus.invalid => _Failure(
                  message:
                      action.message ?? 'We could not verify your licence.',
                ),
                _ => const _Nothing(),
              },
            ),
          );
        },
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: AppSpacing.lg),
          Text('Verifying your licence...', style: AppTextStyles.bodyLarge),
        ],
      ),
    );
  }
}

class _Success extends StatelessWidget {
  const _Success();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle_outline, size: 64, color: context.colors.brand),
        const SizedBox(height: AppSpacing.lg),
        const Text('Licence verified', style: AppTextStyles.title),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Your driving licence is saved.',
          style: AppTextStyles.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.xl),
        FilledButton(
          onPressed: () {
            context.read<ProfileBloc>().add(const ProfileActionAcknowledged());
            // Back past the change form to the licence screen.
            if (context.canPop()) context.pop();
            if (context.canPop()) context.pop();
          },
          child: const Text('Done'),
        ),
      ],
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 64, color: colors.danger),
          const SizedBox(height: AppSpacing.lg),
          const Text('Verification failed', style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: AppTextStyles.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: () =>
                context.read<ProfileBloc>().add(const ProfileLicenceRetried()),
            child: const Text('Retry'),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(
            onPressed: () => context.canPop() ? context.pop() : null,
            child: const Text('Edit details'),
          ),
        ],
      ),
    );
  }
}

class _Nothing extends StatelessWidget {
  const _Nothing();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'There is nothing to verify right now.',
          style: AppTextStyles.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.lg),
        OutlinedButton(
          onPressed: () => context.canPop() ? context.pop() : null,
          child: const Text('Back'),
        ),
      ],
    );
  }
}
