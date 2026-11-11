import 'package:flutter/material.dart';
import 'package:veloce/core/layout/responsive.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';

/// `/profile/about`: what Veloce is and which version this is.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  /// Keep in step with `version` in `pubspec.yaml`.
  static const String versionText = 'Version 1.0.0';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: Responsive.pagePadding(context)
            .copyWith(top: AppSpacing.xl, bottom: AppSpacing.xl),
        children: [
          Icon(
            Icons.directions_car_filled,
            size: 64,
            color: context.colors.brand,
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Veloce',
            style: AppTextStyles.display,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            versionText,
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          const Text(
            'Veloce is a peer-to-peer car rental app for Rwanda. Car owners '
            'list their vehicles and renters book them for the days they '
            'need, with a refundable caution held through MTN MoMo and a '
            'photo checklist at pickup and return so both sides are '
            'protected.',
            style: AppTextStyles.bodyLarge,
          ),
        ],
      ),
    );
  }
}
