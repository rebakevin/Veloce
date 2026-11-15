import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:veloce/core/data/services/user_lookup.dart';
import 'package:veloce/core/data/services/vehicle_lookup.dart';
import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/layout/responsive.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/widgets/empty_state.dart';
import 'package:veloce/core/widgets/error_view.dart';
import 'package:veloce/core/widgets/loading_view.dart';
import 'package:veloce/core/widgets/page_app_bar.dart';

import '../../domain/repositories/review_repository.dart';
import '../bloc/my_reviews_cubit.dart';
import '../widgets/review_card.dart';

class ProfileReviewsPage extends StatelessWidget {
  const ProfileReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (!GetIt.instance.isRegistered<ReviewRepository>() ||
        !GetIt.instance.isRegistered<UserLookup>() ||
        !GetIt.instance.isRegistered<VehicleLookup>() ||
        !GetIt.instance.isRegistered<AuthSession>()) {
      return const Scaffold(
        appBar: PageAppBar(title: 'My reviews'),
        body: SizedBox.shrink(),
      );
    }
    return BlocProvider<MyReviewsCubit>(
      create: (_) => MyReviewsCubit(
        repository: GetIt.instance<ReviewRepository>(),
        userLookup: GetIt.instance<UserLookup>(),
        vehicleLookup: GetIt.instance<VehicleLookup>(),
        session: GetIt.instance<AuthSession>(),
      )..load(),
      child: const ProfileReviewsView(),
    );
  }
}

class ProfileReviewsView extends StatelessWidget {
  const ProfileReviewsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PageAppBar(title: 'My reviews'),
      body: BlocBuilder<MyReviewsCubit, MyReviewsState>(
        builder: (context, state) => switch (state) {
          MyReviewsLoading() => const LoadingView(),
          MyReviewsFailure(:final error) => ErrorView(
            message: error.message,
            onRetry: () => context.read<MyReviewsCubit>().load(),
          ),
          MyReviewsEmpty() => const EmptyState(
            icon: Icons.rate_review_outlined,
            title: 'No reviews written',
            message:
                'Reviews you write after completing rentals will appear here.',
          ),
          MyReviewsLoaded(:final reviews) => ListView.separated(
            padding: Responsive.pagePadding(context)
                .copyWith(top: AppSpacing.md, bottom: AppSpacing.xl),
            itemCount: reviews.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final item = reviews[index];
              return ReviewCard(
                review: item.review,
                titleOverride: item.subjectTitle,
                onEdit: () {
                  context.push(RouteNames.bookingReview(item.review.bookingId));
                },
              );
            },
          ),
        },
      ),
    );
  }
}
