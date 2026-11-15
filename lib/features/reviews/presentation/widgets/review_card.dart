import 'package:flutter/material.dart';
import 'package:veloce/core/domain/entities/review.dart';
import 'package:veloce/core/formatting/formatters.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/rating_stars.dart';
import 'package:veloce/core/widgets/status_chip.dart';
import 'package:veloce/core/widgets/user_avatar.dart';

/// Displays a single review with author/subject info, stars, date, and comment.
class ReviewCard extends StatelessWidget {
  const ReviewCard({
    required this.review,
    super.key,
    this.authorName,
    this.authorPhotoUrl,
    this.titleOverride,
    this.onEdit,
  });

  final Review review;
  final String? authorName;
  final String? authorPhotoUrl;
  final String? titleOverride;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final displayName = titleOverride ?? authorName ?? 'User';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (authorName != null || authorPhotoUrl != null) ...[
                UserAvatar(
                  name: displayName,
                  photoUrl: authorPhotoUrl,
                  radius: 18,
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName, style: AppTextStyles.cardTitle),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          Formatters.date(review.createdAt),
                          style: AppTextStyles.caption.copyWith(
                            color: colors.inkSoft,
                          ),
                        ),
                        if (review.editedAt != null) ...[
                          const SizedBox(width: AppSpacing.xs),
                          const StatusChip(
                            label: 'Edited',
                            tone: StatusTone.neutral,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              RatingStars(rating: review.stars.toDouble(), count: 1),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(review.comment, style: AppTextStyles.body),
          if (onEdit != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit review'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
