import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:veloce/core/layout/responsive.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/empty_state.dart';
import 'package:veloce/core/widgets/error_view.dart';
import 'package:veloce/core/widgets/loading_view.dart';
import 'package:veloce/core/widgets/page_app_bar.dart';
import 'package:veloce/core/widgets/rating_stars.dart';
import 'package:veloce/core/widgets/status_chip.dart';
import 'package:veloce/core/widgets/user_avatar.dart';
import 'package:veloce/features/discovery/discovery.dart';
import 'package:veloce/features/reviews/reviews.dart';

import '../../domain/entities/public_profile.dart';
import '../bloc/public_profile_cubit.dart';

/// Public profile `/user/:id`. Hosts the owner-cars (Phase 3) and
/// reviews-preview (Phase 6) slots. Contact details are never shown here.
class PublicProfilePage extends StatelessWidget {
  const PublicProfilePage({required this.userId, super.key});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PublicProfileCubit>(
      create: (_) => GetIt.instance<PublicProfileCubit>(param1: userId)..load(),
      child: PublicProfileView(userId: userId),
    );
  }
}

/// The public profile screen; needs a [PublicProfileCubit] above it.
class PublicProfileView extends StatelessWidget {
  const PublicProfileView({required this.userId, super.key});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PageAppBar(title: 'Profile'),
      body: BlocBuilder<PublicProfileCubit, PublicProfileState>(
        builder: (context, state) => switch (state) {
          PublicProfileLoading() => const LoadingView(),
          PublicProfileNotFound() => const EmptyState(
            icon: Icons.person_off_outlined,
            title: 'User not found',
            message: 'This profile does not exist or was removed.',
          ),
          PublicProfileFailure(:final error) => ErrorView(
            message: error.message,
            onRetry: () => context.read<PublicProfileCubit>().load(),
          ),
          PublicProfileLoaded(:final profile) => ListView(
            padding: Responsive.pagePadding(context)
                .copyWith(top: AppSpacing.lg, bottom: AppSpacing.xl),
            children: [
              _Summary(profile: profile),
              const SizedBox(height: AppSpacing.xl),
              OwnerCarsSection(ownerId: userId),
              const SizedBox(height: AppSpacing.lg),
              ReviewsPreviewSection(userId: userId),
            ],
          ),
        },
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.profile});

  final PublicProfile profile;

  @override
  Widget build(BuildContext context) {
    final rentals = profile.completedCount;
    return Column(
      children: [
        UserAvatar(name: profile.name, photoUrl: profile.photoUrl, radius: 44),
        const SizedBox(height: AppSpacing.md),
        Text(
          profile.name,
          style: AppTextStyles.title,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        RatingStars(rating: profile.ratingAvg, count: profile.ratingCount),
        const SizedBox(height: AppSpacing.sm),
        Text(
          rentals == 1 ? '1 past rental' : '$rentals past rentals',
          style: AppTextStyles.bodyLarge,
        ),
        if (profile.isFirstTime) ...[
          const SizedBox(height: AppSpacing.sm),
          const StatusChip(label: 'First-time user', tone: StatusTone.info),
        ],
      ],
    );
  }
}
