import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:veloce/core/data/services/booking_lookup.dart';
import 'package:veloce/core/data/services/user_lookup.dart';
import 'package:veloce/core/data/services/vehicle_lookup.dart';
import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/primary_button.dart';
import 'package:veloce/core/widgets/section_header.dart';
import 'package:veloce/core/widgets/status_chip.dart';

import '../../domain/repositories/review_repository.dart';
import '../bloc/post_rental_cubit.dart';
import 'review_card.dart';

/// Shows "review due" prompts and written reviews on the booking detail screen.
class PostRentalSection extends StatelessWidget {
  const PostRentalSection({required this.bookingId, super.key});

  final String bookingId;

  @override
  Widget build(BuildContext context) {
    if (!GetIt.instance.isRegistered<ReviewRepository>() ||
        !GetIt.instance.isRegistered<BookingLookup>() ||
        !GetIt.instance.isRegistered<UserLookup>() ||
        !GetIt.instance.isRegistered<VehicleLookup>() ||
        !GetIt.instance.isRegistered<AuthSession>()) {
      return const SizedBox.shrink();
    }
    return BlocProvider<PostRentalCubit>(
      create: (_) => PostRentalCubit(
        repository: GetIt.instance<ReviewRepository>(),
        bookingLookup: GetIt.instance<BookingLookup>(),
        userLookup: GetIt.instance<UserLookup>(),
        vehicleLookup: GetIt.instance<VehicleLookup>(),
        session: GetIt.instance<AuthSession>(),
        bookingId: bookingId,
      )..load(),
      child: PostRentalView(bookingId: bookingId),
    );
  }
}

class PostRentalView extends StatelessWidget {
  const PostRentalView({required this.bookingId, super.key});

  final String bookingId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PostRentalCubit, PostRentalState>(
      builder: (context, state) {
        if (state is! PostRentalLoaded) {
          return const SizedBox.shrink();
        }

        final colors = context.colors;
        final hasPending = state.hasPendingReview;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Reviews'),
            if (hasPending) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.cautionWash,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.cautionInk.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.rate_review_rounded,
                          color: colors.cautionInk,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Review due',
                          style: AppTextStyles.cardTitle.copyWith(
                            color: colors.cautionInk,
                          ),
                        ),
                        const Spacer(),
                        const StatusChip(
                          label: 'Action required',
                          tone: StatusTone.caution,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      state.isRenter
                          ? (state.ownerReview == null &&
                                    state.vehicleReview == null
                                ? 'Tell others how your rental went. Please review the owner and vehicle.'
                                : state.ownerReview == null
                                ? 'Please review the owner to complete your feedback.'
                                : 'Please review the vehicle to complete your feedback.')
                          : 'Please leave a review for ${state.otherUser?.name ?? 'the renter'}.',
                      style: AppTextStyles.body.copyWith(
                        color: colors.cautionBody,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    PrimaryButton(
                      label: 'Write review',
                      onPressed: () async {
                        await context.push(RouteNames.bookingReview(bookingId));
                        if (context.mounted) {
                          context.read<PostRentalCubit>().load();
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (state.isRenter) ...[
              if (state.ownerReview != null) ...[
                ReviewCard(
                  review: state.ownerReview!,
                  titleOverride:
                      'Review for owner: ${state.otherUser?.name ?? 'Owner'}',
                  onEdit: () async {
                    await context.push(RouteNames.bookingReview(bookingId));
                    if (context.mounted) {
                      context.read<PostRentalCubit>().load();
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              if (state.vehicleReview != null) ...[
                ReviewCard(
                  review: state.vehicleReview!,
                  titleOverride:
                      'Review for car: ${state.vehicle?.make ?? ''} ${state.vehicle?.model ?? ''}',
                  onEdit: () async {
                    await context.push(RouteNames.bookingReview(bookingId));
                    if (context.mounted) {
                      context.read<PostRentalCubit>().load();
                    }
                  },
                ),
              ],
            ] else ...[
              if (state.renterReview != null) ...[
                ReviewCard(
                  review: state.renterReview!,
                  titleOverride:
                      'Review for renter: ${state.otherUser?.name ?? 'Renter'}',
                  onEdit: () async {
                    await context.push(RouteNames.bookingReview(bookingId));
                    if (context.mounted) {
                      context.read<PostRentalCubit>().load();
                    }
                  },
                ),
              ],
            ],
          ],
        );
      },
    );
  }
}
