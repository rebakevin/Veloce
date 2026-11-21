import 'package:flutter/material.dart';

import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';

/// The welcome screen's centred logo tile, wordmark and tagline.
class WelcomeHero extends StatelessWidget {
  const WelcomeHero({super.key});

  static const double _tile = 96;
  static const double _tileRadius = 30;
  static const double _tileIcon = 58;
  static const double _wordmark = 60;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.brand,
            borderRadius: BorderRadius.circular(_tileRadius),
          ),
          child: SizedBox.square(
            dimension: _tile,
            child: Icon(
              Icons.directions_car_outlined,
              color: colors.onBrand,
              size: _tileIcon,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'veloce',
          style: AppTextStyles.display.copyWith(
            color: colors.ink,
            fontSize: _wordmark,
            height: 1,
            letterSpacing: -2.4,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Cars from your neighbours, in Kigali.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyLarge.copyWith(
            color: colors.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
