import 'package:flutter/material.dart';
import 'package:veloce/core/layout/responsive.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/page_app_bar.dart';

/// `/profile/about`: what Veloce is and which version this is.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  /// Keep in step with `version` in `pubspec.yaml`.
  static const String versionText = 'Version 1.0.0';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PageAppBar(title: 'About'),
      body: ListView(
        padding: Responsive.pagePadding(context)
            .copyWith(top: AppSpacing.sm, bottom: AppSpacing.xl),
        children: [
          const _AboutCard(
            title: 'Veloce',
            titleStyle: AppTextStyles.title,
            body:
                'Veloce is a peer-to-peer car rental app for Rwanda. Car '
                'owners list their vehicles and renters book them for the '
                'days they need, with a refundable caution held through MTN '
                'MoMo and a photo checklist at pickup and return so both '
                'sides are protected.',
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            versionText,
            style: AppTextStyles.caption.copyWith(color: context.colors.muted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard({
    required this.title,
    required this.body,
    this.titleStyle = AppTextStyles.cardTitle,
  });

  final String title;
  final String body;
  final TextStyle titleStyle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: titleStyle.copyWith(color: colors.ink)),
            const SizedBox(height: AppSpacing.sm),
            Text(body, style: AppTextStyles.body.copyWith(color: colors.body)),
          ],
        ),
      ),
    );
  }
}
