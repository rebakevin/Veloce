import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Stand-in for a screen a later phase will build. The owning phase replaces
/// the route's builder; nothing else changes.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({
    required this.title,
    required this.route,
    required this.phase,
    super.key,
  });

  final String title;
  final String route;
  final int phase;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Phase $phase', style: AppTextStyles.label),
              const SizedBox(height: AppSpacing.sm),
              Text(
                title,
                style: AppTextStyles.title,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(route, style: AppTextStyles.plate.copyWith(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}
