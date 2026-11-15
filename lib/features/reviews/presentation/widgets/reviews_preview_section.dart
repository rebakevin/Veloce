import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:veloce/core/data/services/user_lookup.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/widgets/rating_stars.dart';
import 'package:veloce/core/widgets/section_header.dart';

import '../../domain/repositories/review_repository.dart';
import '../bloc/reviews_preview_cubit.dart';
import '../widgets/review_card.dart';

/// Shows up to 3 reviews for a user on their public profile page.
/// Owned by Phase 6 — replaces the placeholder.
class ReviewsPreviewSection extends StatelessWidget {
  const ReviewsPreviewSection({required this.userId, super.key});

  final String userId;

  @override
  Widget build(BuildContext context) {
    if (!GetIt.instance.isRegistered<ReviewRepository>() ||
        !GetIt.instance.isRegistered<UserLookup>()) {
      return const SizedBox.shrink();
    }
    return BlocProvider<ReviewsPreviewCubit>(
      create: (_) => ReviewsPreviewCubit(
        repository: GetIt.instance<ReviewRepository>(),
        userLookup: GetIt.instance<UserLookup>(),
        userId: userId,
      )..load(),
      child: const _ReviewsPreviewView(),
    );
  }
}

class _ReviewsPreviewView extends StatelessWidget {
  const _ReviewsPreviewView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReviewsPreviewCubit, ReviewsPreviewState>(
      builder: (context, state) => switch (state) {
        ReviewsPreviewLoading() => const SizedBox.shrink(),
        ReviewsPreviewEmpty() => const SizedBox.shrink(),
        ReviewsPreviewFailure() => const SizedBox.shrink(),
        ReviewsPreviewLoaded(
          :final items,
          :final totalCount,
          :final averageRating,
          :final userId,
        ) =>
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Reviews',
                actionLabel: 'See all ($totalCount)',
                onAction: () => context.push(RouteNames.userReviews(userId)),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  RatingStars(rating: averageRating, count: totalCount),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ReviewCard(
                    review: item.review,
                    authorName: item.authorName ?? 'User',
                    authorPhotoUrl: item.authorPhotoUrl,
                  ),
                ),
              ),
            ],
          ),
      },
    );
  }
}
