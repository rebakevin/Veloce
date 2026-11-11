import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'placeholder_link.dart';

/// The mock's outgoing navigation for a placeholder screen or slot.
class PlaceholderLinks extends StatelessWidget {
  const PlaceholderLinks({required this.links, super.key});

  final List<PlaceholderLink> links;

  @override
  Widget build(BuildContext context) {
    if (links.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Opens from here', style: AppTextStyles.label),
        const SizedBox(height: AppSpacing.sm),
        for (final link in links)
          ListTile(
            minTileHeight: AppSizes.iconControl,
            title: Text(link.label),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                link.isTab ? context.go(link.path) : context.push(link.path),
          ),
      ],
    );
  }
}
