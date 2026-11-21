import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:veloce/core/data/services/user_lookup.dart';
import 'package:veloce/core/data/services/vehicle_lookup.dart';
import 'package:veloce/core/domain/entities/user_account.dart';
import 'package:veloce/core/domain/enums/subject_type.dart';
import 'package:veloce/core/layout/responsive.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/empty_state.dart';
import 'package:veloce/core/widgets/error_view.dart';
import 'package:veloce/core/widgets/loading_view.dart';
import 'package:veloce/core/widgets/page_app_bar.dart';
import 'package:veloce/core/widgets/rating_stars.dart';
import 'package:veloce/core/widgets/user_avatar.dart';

import '../../domain/repositories/review_repository.dart';
import '../bloc/subject_reviews_cubit.dart';
import '../widgets/review_card.dart';

class UserReviewsPage extends StatelessWidget {
  const UserReviewsPage({required this.userId, super.key});

  final String userId;

  @override
  Widget build(BuildContext context) {
    if (!GetIt.instance.isRegistered<ReviewRepository>() ||
        !GetIt.instance.isRegistered<VehicleLookup>() ||
        !GetIt.instance.isRegistered<UserLookup>()) {
      return const Scaffold(
        appBar: PageAppBar(title: 'Reviews'),
        body: SizedBox.shrink(),
      );
    }
    return BlocProvider<SubjectReviewsCubit>(
      create: (_) => SubjectReviewsCubit(
        repository: GetIt.instance<ReviewRepository>(),
        vehicleLookup: GetIt.instance<VehicleLookup>(),
        userLookup: GetIt.instance<UserLookup>(),
        subjectType: SubjectType.user,
        subjectId: userId,
      )..load(),
      child: const UserReviewsView(),
    );
  }
}

class UserReviewsView extends StatelessWidget {
  const UserReviewsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PageAppBar(title: 'Reviews received'),
      body: BlocBuilder<SubjectReviewsCubit, SubjectReviewsState>(
        builder: (context, state) => switch (state) {
          SubjectReviewsLoading() => const LoadingView(),
          SubjectReviewsFailure(:final error) => ErrorView(
            message: error.message,
            onRetry: () => context.read<SubjectReviewsCubit>().load(),
          ),
          SubjectReviewsEmpty(:final user) => Column(
            children: [
              if (user != null) _UserHeader(user: user),
              const Expanded(
                child: EmptyState(
                  icon: Icons.rate_review_outlined,
                  title: 'No reviews yet',
                  message: 'Reviews from other members after rentals will appear here.',
                ),
              ),
            ],
          ),
          SubjectReviewsLoaded(:final reviews, :final user) =>
            ListView.separated(
              padding: Responsive.pagePadding(context)
                  .copyWith(top: AppSpacing.md, bottom: AppSpacing.xl),
              itemCount: reviews.length + 1,
              separatorBuilder: (_, index) => index == 0
                  ? const SizedBox(height: AppSpacing.lg)
                  : const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return user != null
                      ? _UserHeader(user: user)
                      : const SizedBox.shrink();
                }
                final item = reviews[index - 1];
                return ReviewCard(
                  review: item.review,
                  authorName: item.authorName ?? 'User',
                  authorPhotoUrl: item.authorPhotoUrl,
                );
              },
            ),
        },
      ),
    );
  }
}

class _UserHeader extends StatelessWidget {
  const _UserHeader({required this.user});

  final UserAccount user;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        children: [
          UserAvatar(name: user.name, photoUrl: user.photoUrl, radius: 24),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, style: AppTextStyles.cardTitle),
                const SizedBox(height: 2),
                RatingStars(rating: user.ratingAvg, count: user.ratingCount),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
