import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';

class CarPublishedPage extends StatelessWidget {
  const CarPublishedPage({required this.vehicleId, super.key});

  final String vehicleId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, size: 72),
              const SizedBox(height: AppSpacing.lg),
              const Text('Your car is live', style: AppTextStyles.cardTitle),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Renters can find it now. You can pause it or change the '
                'price any time from My cars.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: () => context.go(RouteNames.ownerHome),
                child: const Text('Back to home'),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                onPressed: () => context.push(RouteNames.car(vehicleId)),
                child: const Text('View listing'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
