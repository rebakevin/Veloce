import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:veloce/core/domain/entities/review.dart';
import 'package:veloce/core/domain/enums/subject_type.dart';
import 'package:veloce/core/formatting/formatters.dart';
import 'package:veloce/core/layout/responsive.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/app_messenger.dart';
import 'package:veloce/core/widgets/app_text_field.dart';
import 'package:veloce/core/widgets/error_view.dart';
import 'package:veloce/core/widgets/loading_view.dart';
import 'package:veloce/core/widgets/page_app_bar.dart';
import 'package:veloce/core/widgets/primary_button.dart';
import 'package:veloce/core/widgets/rating_stars.dart';
import 'package:veloce/core/widgets/status_chip.dart';

import '../bloc/review_bloc.dart';

class BookingReviewPage extends StatelessWidget {
  const BookingReviewPage({required this.bookingId, super.key});

  final String bookingId;

  @override
  Widget build(BuildContext context) {
    if (!GetIt.instance.isRegistered<ReviewBloc>()) {
      return const Scaffold(
        appBar: PageAppBar(title: 'Write a review'),
        body: SizedBox.shrink(),
      );
    }
    return BlocProvider<ReviewBloc>(
      create: (_) =>
          GetIt.instance<ReviewBloc>()..add(ReviewStarted(bookingId)),
      child: BookingReviewView(bookingId: bookingId),
    );
  }
}

class BookingReviewView extends StatefulWidget {
  const BookingReviewView({this.bookingId, super.key});

  /// Used by the retry button of the load error view.
  final String? bookingId;

  @override
  State<BookingReviewView> createState() => _BookingReviewViewState();
}

class _BookingReviewViewState extends State<BookingReviewView> {
  final TextEditingController _ownerCommentController = TextEditingController();
  final TextEditingController _vehicleCommentController =
      TextEditingController();
  final TextEditingController _renterCommentController =
      TextEditingController();

  @override
  void dispose() {
    _ownerCommentController.dispose();
    _vehicleCommentController.dispose();
    _renterCommentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messenger = GetIt.instance<AppMessenger>();

    return Scaffold(
      appBar: const PageAppBar(title: 'Review rental'),
      body: BlocConsumer<ReviewBloc, ReviewState>(
        listenWhen: (prev, curr) =>
            prev.status != curr.status ||
            prev.failure != curr.failure ||
            prev.successMessage != curr.successMessage,
        listener: (context, state) {
          if (state.status == ReviewStatus.success &&
              state.successMessage != null) {
            messenger.success(state.successMessage!);
          } else if (state.status == ReviewStatus.failure &&
              state.failure != null) {
            messenger.failure(state.failure!);
          }

          // Sync initial or updated comment controllers
          if (_ownerCommentController.text.isEmpty &&
              state.ownerComment.isNotEmpty) {
            _ownerCommentController.text = state.ownerComment;
          }
          if (_vehicleCommentController.text.isEmpty &&
              state.vehicleComment.isNotEmpty) {
            _vehicleCommentController.text = state.vehicleComment;
          }
          if (_renterCommentController.text.isEmpty &&
              state.renterComment.isNotEmpty) {
            _renterCommentController.text = state.renterComment;
          }
        },
        builder: (context, state) {
          return switch (state.status) {
            ReviewStatus.initial || ReviewStatus.loading => const LoadingView(),
            ReviewStatus.failure when state.booking == null => ErrorView(
              message:
                  state.failure?.message ?? 'Could not load rental details.',
              onRetry: () {
                final id = widget.bookingId;
                if (id != null) {
                  context.read<ReviewBloc>().add(ReviewStarted(id));
                }
              },
            ),
            _ => _buildContent(context, state),
          };
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, ReviewState state) {
    final booking = state.booking!;
    final colors = context.colors;

    return ListView(
      padding: Responsive.pagePadding(context)
          .copyWith(top: AppSpacing.md, bottom: AppSpacing.xl),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.sand,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(booking.reference, style: AppTextStyles.cardTitle),
              const SizedBox(height: 4),
              Text(
                Formatters.dateRange(booking.startDate, booking.endDate),
                style: AppTextStyles.caption.copyWith(color: colors.inkSoft),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (state.isRenter) ...[
          SegmentedButton<SubjectType>(
            segments: [
              ButtonSegment<SubjectType>(
                value: SubjectType.user,
                label: const Text('Owner'),
                icon: state.ownerExistingReview != null
                    ? const Icon(Icons.check_circle, size: 16)
                    : null,
              ),
              ButtonSegment<SubjectType>(
                value: SubjectType.vehicle,
                label: const Text('Vehicle'),
                icon: state.vehicleExistingReview != null
                    ? const Icon(Icons.check_circle, size: 16)
                    : null,
              ),
            ],
            selected: {state.activeSubject},
            onSelectionChanged: (selected) {
              context.read<ReviewBloc>().add(
                ReviewSubjectChanged(selected.first),
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          if (state.activeSubject == SubjectType.user)
            _buildReviewForm(
              context: context,
              title: 'Review owner: ${state.otherUser?.name ?? 'Owner'}',
              subtitle: 'How was communication and handoff with the owner?',
              stars: state.ownerStars,
              starsError: state.ownerStarsError,
              commentController: _ownerCommentController,
              commentError: state.ownerCommentError,
              existingReview: state.ownerExistingReview,
              isSubmitting: state.status == ReviewStatus.submitting,
              onStarsChanged: (stars) => context.read<ReviewBloc>().add(
                ReviewStarsChanged(subjectType: SubjectType.user, stars: stars),
              ),
              onCommentChanged: (comment) => context.read<ReviewBloc>().add(
                ReviewCommentChanged(
                  subjectType: SubjectType.user,
                  comment: comment,
                ),
              ),
              onSubmit: () => context.read<ReviewBloc>().add(
                const ReviewSubmitted(SubjectType.user),
              ),
            )
          else
            _buildReviewForm(
              context: context,
              title:
                  'Review vehicle: ${state.vehicle?.make ?? ''} ${state.vehicle?.model ?? ''}',
              subtitle: 'How was the vehicle condition, cleanliness and driving experience?',
              stars: state.vehicleStars,
              starsError: state.vehicleStarsError,
              commentController: _vehicleCommentController,
              commentError: state.vehicleCommentError,
              existingReview: state.vehicleExistingReview,
              isSubmitting: state.status == ReviewStatus.submitting,
              onStarsChanged: (stars) => context.read<ReviewBloc>().add(
                ReviewStarsChanged(
                  subjectType: SubjectType.vehicle,
                  stars: stars,
                ),
              ),
              onCommentChanged: (comment) => context.read<ReviewBloc>().add(
                ReviewCommentChanged(
                  subjectType: SubjectType.vehicle,
                  comment: comment,
                ),
              ),
              onSubmit: () => context.read<ReviewBloc>().add(
                const ReviewSubmitted(SubjectType.vehicle),
              ),
            ),
        ] else ...[
          _buildReviewForm(
            context: context,
            title: 'Review renter: ${state.otherUser?.name ?? 'Renter'}',
            subtitle: 'How was the rental experience with this renter?',
            stars: state.renterStars,
            starsError: state.renterStarsError,
            commentController: _renterCommentController,
            commentError: state.renterCommentError,
            existingReview: state.renterExistingReview,
            isSubmitting: state.status == ReviewStatus.submitting,
            onStarsChanged: (stars) => context.read<ReviewBloc>().add(
              ReviewStarsChanged(subjectType: SubjectType.user, stars: stars),
            ),
            onCommentChanged: (comment) => context.read<ReviewBloc>().add(
              ReviewCommentChanged(
                subjectType: SubjectType.user,
                comment: comment,
              ),
            ),
            onSubmit: () => context.read<ReviewBloc>().add(
              const ReviewSubmitted(SubjectType.user),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReviewForm({
    required BuildContext context,
    required String title,
    required String subtitle,
    required int stars,
    required String? starsError,
    required TextEditingController commentController,
    required String? commentError,
    required Review? existingReview,
    required bool isSubmitting,
    required ValueChanged<int> onStarsChanged,
    required ValueChanged<String> onCommentChanged,
    required VoidCallback onSubmit,
  }) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(title, style: AppTextStyles.heading)),
            if (existingReview != null)
              const StatusChip(label: 'Reviewed', tone: StatusTone.active),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: AppTextStyles.body.copyWith(color: colors.inkSoft),
        ),
        const SizedBox(height: AppSpacing.lg),
        const Text('Rating *', style: AppTextStyles.caption),
        const SizedBox(height: AppSpacing.xs),
        RatingStars(rating: stars.toDouble(), onChanged: onStarsChanged),
        if (starsError != null) ...[
          const SizedBox(height: 4),
          Text(
            starsError,
            style: AppTextStyles.caption.copyWith(color: colors.danger),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: 'Written comment *',
          hint: 'Write your honest feedback (mandatory)...',
          controller: commentController,
          maxLines: 4,
          onChanged: onCommentChanged,
        ),
        if (commentError != null) ...[
          const SizedBox(height: 4),
          Text(
            commentError,
            style: AppTextStyles.caption.copyWith(color: colors.danger),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: existingReview != null ? 'Update review' : 'Submit review',
          isLoading: isSubmitting,
          onPressed: onSubmit,
        ),
      ],
    );
  }
}
