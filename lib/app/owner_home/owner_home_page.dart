import 'package:flutter/material.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/features/booking/booking.dart';
import 'package:veloce/features/finances/finances.dart';
import 'package:veloce/features/vehicles/vehicles.dart';

/// Owner dashboard. Each card is a slot owned by one phase, so no two phases
/// edit this file.
class OwnerHomePage extends StatelessWidget {
  const OwnerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        children: const [
          Text('Owner dashboard', style: AppTextStyles.title),
          SizedBox(height: AppSpacing.lg),
          PendingRequestsCard(),
          SizedBox(height: AppSpacing.md),
          CarCountCard(),
          SizedBox(height: AppSpacing.md),
          UpcomingRentalsCard(),
          SizedBox(height: AppSpacing.md),
          FinancesCard(),
        ],
      ),
    );
  }
}
