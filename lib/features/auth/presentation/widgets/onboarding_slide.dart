import 'package:flutter/material.dart';

import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';

/// Content of one onboarding slide.
class OnboardingSlideData {
  const OnboardingSlideData({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

const List<OnboardingSlideData> onboardingSlides = [
  OnboardingSlideData(
    icon: Icons.search,
    title: 'Find the right car',
    body: 'Browse cars from local owners across Kigali and pick your dates.',
  ),
  OnboardingSlideData(
    icon: Icons.verified_user_outlined,
    title: 'Rent with confidence',
    body: 'Verified owners and renters, and a caution fee that protects both.',
  ),
  OnboardingSlideData(
    icon: Icons.attach_money,
    title: 'Earn from your car',
    body: 'List your car, set your price and get paid when the trip ends.',
  ),
];

class OnboardingSlide extends StatelessWidget {
  const OnboardingSlide({required this.data, super.key});

  final OnboardingSlideData data;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 56,
            backgroundColor: colors.brandWash,
            child: Icon(data.icon, size: 56, color: colors.brand),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            data.title,
            style: AppTextStyles.display.copyWith(fontSize: 28),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            data.body,
            style: AppTextStyles.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
