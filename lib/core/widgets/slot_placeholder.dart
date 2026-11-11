import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'placeholder_link.dart';
import 'placeholder_links.dart';

/// Placeholder for a widget one phase owns inside a page several phases share
/// (TECHNICAL.md §10). The owner replaces the slot's `build`, not the host page.
class SlotPlaceholder extends StatelessWidget {
  const SlotPlaceholder({
    required this.name,
    required this.phase,
    this.links = const [],
    super.key,
  });

  final String name;
  final int phase;

  /// Where the mock goes from this slot.
  final List<PlaceholderLink> links;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: colors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(name, style: AppTextStyles.cardTitle)),
                Text('Phase $phase', style: AppTextStyles.label),
              ],
            ),
            if (links.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              PlaceholderLinks(links: links),
            ],
          ],
        ),
      ),
    );
  }
}
