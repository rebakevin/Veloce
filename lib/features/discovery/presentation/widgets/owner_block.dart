import 'package:flutter/material.dart';

import 'package:veloce/core/domain/entities/user_account.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/rating_stars.dart';
import 'package:veloce/core/widgets/user_avatar.dart';

/// Owner summary on the car detail page. Contact details stay hidden here.
class OwnerBlock extends StatelessWidget {
  const OwnerBlock({required this.owner, required this.onTap, super.key});

  final UserAccount owner;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            'Owner',
            style: AppTextStyles.bodyLarge.copyWith(
              color: colors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Semantics(
          button: true,
          label: 'View owner profile',
          child: Material(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    UserAvatar(
                      name: owner.name,
                      photoUrl: owner.photoUrl,
                      radius: 26,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            owner.name,
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: colors.ink,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          RatingStars(
                            rating: owner.ratingAvg,
                            count: owner.ratingCount,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Contact details unlock after you pay',
                            style: AppTextStyles.label.copyWith(
                              color: colors.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: colors.brand),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
