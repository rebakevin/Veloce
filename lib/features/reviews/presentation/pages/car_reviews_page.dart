import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:veloce/core/data/services/user_lookup.dart';
import 'package:veloce/core/data/services/vehicle_lookup.dart';
import 'package:veloce/core/domain/entities/vehicle.dart';
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

import '../../domain/repositories/review_repository.dart';
import '../bloc/subject_reviews_cubit.dart';
import '../widgets/review_card.dart';

class CarReviewsPage extends StatelessWidget {
  const CarReviewsPage({required this.carId, super.key});

  final String carId;

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
        subjectType: SubjectType.vehicle,
        subjectId: carId,
      )..load(),
      child: const CarReviewsView(),
    );
  }
}

class CarReviewsView extends StatelessWidget {
  const CarReviewsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PageAppBar(title: 'Car reviews'),
      body: BlocBuilder<SubjectReviewsCubit, SubjectReviewsState>(
        builder: (context, state) => switch (state) {
          SubjectReviewsLoading() => const LoadingView(),
          SubjectReviewsFailure(:final error) => ErrorView(
            message: error.message,
            onRetry: () => context.read<SubjectReviewsCubit>().load(),
          ),
          SubjectReviewsEmpty(:final vehicle) => Column(
            children: [
              if (vehicle != null) _VehicleHeader(vehicle: vehicle),
              const Expanded(
                child: EmptyState(
                  icon: Icons.rate_review_outlined,
                  title: 'No reviews yet',
                  message:
                      'Reviews left by renters after trips will appear here.',
                ),
              ),
            ],
          ),
          SubjectReviewsLoaded(:final reviews, :final vehicle) =>
            ListView.separated(
              padding: Responsive.pagePadding(context)
                  .copyWith(top: AppSpacing.md, bottom: AppSpacing.xl),
              itemCount: reviews.length + 1,
              separatorBuilder: (_, index) => index == 0
                  ? const SizedBox(height: AppSpacing.lg)
                  : const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return vehicle != null
                      ? _VehicleHeader(vehicle: vehicle)
                      : const SizedBox.shrink();
                }
                final item = reviews[index - 1];
                return ReviewCard(
                  review: item.review,
                  authorName: item.authorName ?? 'Renter',
                  authorPhotoUrl: item.authorPhotoUrl,
                );
              },
            ),
        },
      ),
    );
  }
}

class _VehicleHeader extends StatelessWidget {
  const _VehicleHeader({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${vehicle.make} ${vehicle.model} (${vehicle.year})',
                  style: AppTextStyles.cardTitle,
                ),
                const SizedBox(height: 2),
                Text(vehicle.plate, style: AppTextStyles.caption),
              ],
            ),
          ),
          RatingStars(rating: vehicle.ratingAvg, count: vehicle.ratingCount),
        ],
      ),
    );
  }
}
