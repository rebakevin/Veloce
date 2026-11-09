import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Placeholder for a widget one phase owns inside a page several phases share
/// (TECHNICAL.md §10). The owner replaces the slot's `build`, not the host page.
class SlotPlaceholder extends StatelessWidget {
  const SlotPlaceholder({required this.name, required this.phase, super.key});

  final String name;
  final int phase;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.paper,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Expanded(child: Text(name, style: AppTextStyles.cardTitle)),
            Text('Phase $phase', style: AppTextStyles.label),
          ],
        ),
      ),
    );
  }
}
