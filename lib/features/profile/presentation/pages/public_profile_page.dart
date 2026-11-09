import 'package:flutter/material.dart';

import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/features/discovery/discovery.dart';
import 'package:veloce/features/reviews/reviews.dart';

/// Public profile `/user/:id` (Phase 1). Hosts the owner-cars (Phase 3) and
/// reviews-preview (Phase 6) slots. Contact details are never shown here.
class PublicProfilePage extends StatelessWidget {
  const PublicProfilePage({required this.userId, super.key});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        children: [
          const Text('Phase 1: public profile'),
          Text(RouteNames.user(userId)),
          const SizedBox(height: AppSpacing.lg),
          OwnerCarsSection(ownerId: userId),
          const SizedBox(height: AppSpacing.lg),
          ReviewsPreviewSection(userId: userId),
        ],
      ),
    );
  }
}
