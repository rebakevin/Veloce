import 'package:flutter/material.dart';

import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';

/// One big tappable choice on the role step.
class RoleCard extends StatelessWidget {
  const RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      label: '$title. $description',
      excludeSemantics: true,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.brandWash,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: SizedBox.square(
                    dimension: 52,
                    child: Icon(icon, color: colors.brand, size: 26),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.cardTitle.copyWith(
                          color: colors.ink,
                          fontSize: 19,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(description, style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: colors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
