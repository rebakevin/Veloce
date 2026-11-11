import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:veloce/core/widgets/error_view.dart';
import 'package:veloce/core/widgets/loading_view.dart';

import '../bloc/profile_bloc.dart';

/// Builds [builder] once the profile is loaded; shows the loading and error
/// views (with Retry) otherwise. A reload keeps the old content on screen.
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
