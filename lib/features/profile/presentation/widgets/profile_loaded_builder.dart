import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/widgets/error_view.dart';
import 'package:veloce/core/widgets/loading_view.dart';

import 'package:veloce/features/auth/auth.dart';

import '../bloc/profile_bloc.dart';

/// Builds [builder] once the profile is loaded; shows the loading and error
/// views (with Retry, or Sign out when the profile does not exist) otherwise. A reload keeps the old content on screen.
class ProfileLoadedBuilder extends StatelessWidget {
  const ProfileLoadedBuilder({required this.builder, super.key});

  final Widget Function(BuildContext context, ProfileLoaded state) builder;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      buildWhen: (previous, current) =>
          !(previous is ProfileLoaded && current is ProfileLoading),
      builder: (context, state) => switch (state) {
        ProfileLoading() => const LoadingView(),
        // Signed in, but the profile is gone (a half-finished account
        // deletion): retrying cannot help, so the only way out is to sign out.
        ProfileFailure(error: NotFoundFailure()) => ErrorView(
          message: 'This account no longer has a profile.',
          retryLabel: 'Sign out',
          onRetry: () => context.read<AuthBloc>().add(const SignOutRequested()),
        ),
        ProfileFailure(:final error) => ErrorView(
          message: error.message,
          onRetry: () =>
              context.read<ProfileBloc>().add(const ProfileStarted()),
        ),
        final ProfileLoaded loaded => builder(context, loaded),
      },
    );
  }
}
