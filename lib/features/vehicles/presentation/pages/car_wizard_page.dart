import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';

import '../../domain/entities/wizard_draft.dart';
import '../../domain/entities/wizard_step.dart';
import '../bloc/car_wizard_bloc.dart';
import '../widgets/details_step.dart';
import '../widgets/media_step.dart';
import '../widgets/pricing_step.dart';
import '../widgets/rules_step.dart';
import '../widgets/specs_step.dart';

class CarWizardPage extends StatelessWidget {
  const CarWizardPage({super.key});

  static const Map<WizardStep, String> _titles = {
    WizardStep.media: 'Photos',
    WizardStep.details: 'Vehicle details',
    WizardStep.specs: 'Specifications',
    WizardStep.pricing: 'Pricing',
    WizardStep.rules: 'Rental rules',
    WizardStep.documents: 'Documents',
    WizardStep.review: 'Review and publish',
  };

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CarWizardBloc, CarWizardState>(
      builder: (context, state) {
        final bloc = context.read<CarWizardBloc>();
        void change(WizardDraft draft) => bloc.add(WizardDraftChanged(draft));
        final total = WizardStep.values.length;
        return Scaffold(
          appBar: AppBar(
            title: const Text('List a car'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(4),
              child: LinearProgressIndicator(
                value: (state.step.index + 1) / total,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Step ${state.step.index + 1} of $total',
                  style: AppTextStyles.label,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(_titles[state.step]!, style: AppTextStyles.cardTitle),
                const SizedBox(height: AppSpacing.lg),
                switch (state.step) {
                  WizardStep.media => MediaStep(
                    draft: state.draft,
                    errors: state.errors,
                    onChanged: change,
                  ),
                  WizardStep.details => DetailsStep(
                    draft: state.draft,
                    errors: state.errors,
                    onChanged: change,
                  ),
                  WizardStep.specs => SpecsStep(
                    draft: state.draft,
                    errors: state.errors,
                    onChanged: change,
                  ),
                  WizardStep.pricing => PricingStep(
                    draft: state.draft,
                    errors: state.errors,
                    onChanged: change,
                  ),
                  WizardStep.rules => RulesStep(
                    draft: state.draft,
                    errors: state.errors,
                    onChanged: change,
                  ),
                  WizardStep.documents ||
                  WizardStep.review => const Text('This step is built next.'),
                },
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  if (!state.isFirstStep) ...[
                    OutlinedButton(
                      onPressed: () => bloc.add(const WizardBackPressed()),
                      child: const Text('Back'),
                    ),
                    const SizedBox(width: AppSpacing.md),
                  ],
                  Expanded(
                    child: FilledButton(
                      onPressed: state.isLastStep
                          ? null
                          : () => bloc.add(const WizardNextPressed()),
                      child: Text(state.isLastStep ? 'Publish' : 'Next'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
