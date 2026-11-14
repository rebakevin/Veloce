import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'page_app_bar.dart';
import 'placeholder_link.dart';
import 'placeholder_links.dart';

/// Stand-in for a screen a later phase will build. The owning phase replaces
/// the route's builder; nothing else changes.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({
    required this.title,
    required this.route,
    required this.phase,
    this.links = const [],
    super.key,
  });

  final String title;
  final String route;
  final int phase;

  /// Where the mock goes from this screen.
  final List<PlaceholderLink> links;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PageAppBar(title: title),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Phase $phase',
                style: AppTextStyles.label,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                title,
                style: AppTextStyles.title,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                route,
                style: AppTextStyles.plate.copyWith(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              if (links.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                PlaceholderLinks(links: links),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
