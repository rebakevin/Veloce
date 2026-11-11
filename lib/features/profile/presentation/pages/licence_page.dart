import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:veloce/core/formatting/formatters.dart';
import 'package:veloce/core/layout/responsive.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/widgets/empty_state.dart';
import 'package:veloce/core/widgets/primary_button.dart';
import 'package:veloce/core/widgets/status_chip.dart';

import '../widgets/profile_loaded_builder.dart';

/// `/profile/licence` (step 1 of 3): the current licence, with a way to add
/// or change it. Change form: `/profile/licence/change`; result:
/// `/profile/licence/verify`.
class LicencePage extends StatelessWidget {
  const LicencePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driving licence')),
      body: ProfileLoadedBuilder(
        builder: (context, state) {
          final licence = state.licence;
          if (licence == null) {
            return EmptyState(
              icon: Icons.credit_card_outlined,
              title: 'No licence added yet',
              message: 'Add your driving licence to book cars.',
              actionLabel: 'Add licence',
              onAction: () => context.push(RouteNames.profileLicenceChange),
            );
          }
          return ListView(
            padding: Responsive.pagePadding(context)
                .copyWith(top: AppSpacing.lg, bottom: AppSpacing.xl),
            children: [
              Card(
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      title: Text(licence.number),
                      subtitle: const Text('Licence number'),
                      trailing: StatusChip(
                        label: licence.active ? 'Active' : 'Inactive',
                        tone: licence.active
                            ? StatusTone.active
                            : StatusTone.caution,
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: Text(Formatters.date(licence.expiry)),
                      subtitle: const Text('Expires'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Image.network(
                  licence.photoUrl,
                  height: 180,
                  fit: BoxFit.cover,
                  semanticLabel: 'Photo of your driving licence',
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: 'Change licence',
                onPressed: () => context.push(RouteNames.profileLicenceChange),
              ),
            ],
          );
        },
      ),
    );
  }
}
