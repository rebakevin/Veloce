import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/app_messenger.dart';
import 'package:veloce/core/widgets/error_view.dart';
import 'package:veloce/core/widgets/loading_view.dart';

import '../../domain/entities/wizard_draft.dart';
import '../../domain/entities/wizard_step.dart';
import '../bloc/car_wizard_bloc.dart';
import '../widgets/details_step.dart';
import '../widgets/documents_step.dart';
import '../widgets/media_step.dart';
import '../widgets/pricing_step.dart';
import '../widgets/review_step.dart';
import '../widgets/rules_step.dart';
import '../widgets/specs_step.dart';

class CarWizardPage extends StatelessWidget {
  /// Set to edit that car; the route also sends `WizardEditStarted` to the bloc.
  const CarWizardPage({super.key, this.editVehicleId});

  final String? editVehicleId;

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
    return BlocConsumer<CarWizardBloc, CarWizardState>(
      listenWhen: (previous, current) =>
          previous.submission != current.submission,
      listener: (context, state) {
        if (state.submission == WizardSubmission.published) {
          if (state.draft.isEditing) {
            GetIt.I<AppMessenger>().success('Changes saved.');
            context.canPop() ? context.pop() : context.go(RouteNames.ownerCars);
          } else {
            context.pushReplacement(
              RouteNames.ownerCarPublished(state.publishedId!),
            );
          }
        } else if (state.submission == WizardSubmission.failure) {
          GetIt.I<AppMessenger>().error(
            state.message ?? 'We could not save the car. Try again.',
          );
        }
      },
      builder: (context, state) {
        final bloc = context.read<CarWizardBloc>();
        void change(WizardDraft draft) => bloc.add(WizardDraftChanged(draft));
        final total = state.steps.length;
        final stepNumber = state.steps.indexOf(state.step) + 1;
        final editing = editVehicleId != null;
        if (state.submission == WizardSubmission.loading ||
            state.submission == WizardSubmission.loadFailure) {
          return Scaffold(
            appBar: AppBar(title: const Text('Edit car')),
            body: state.submission == WizardSubmission.loading
                ? const LoadingView()
                : ErrorView(
                    message: state.message ?? 'We could not load this car.',
                    onRetry: () => bloc.add(WizardEditStarted(editVehicleId!)),
                  ),
          );
        }
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              tooltip: 'Back',
              icon: const Icon(Icons.arrow_back),
              onPressed: state.isFirstStep
                  ? () => context.pop()
                  : () => bloc.add(const WizardBackPressed()),
            ),
            title: Text(editing ? 'Edit car' : 'List a car'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(4),
              child: LinearProgressIndicator(value: stepNumber / total),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Step $stepNumber of $total',
                        style: AppTextStyles.label,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        editing && state.step == WizardStep.review
                            ? 'Review and save'
                            : _titles[state.step]!,
                        style: AppTextStyles.cardTitle,
                      ),
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
                        WizardStep.documents => DocumentsStep(
                          draft: state.draft,
                          errors: state.errors,
                          verifying: state.verifying,
                          onChanged: change,
                          onVerify: (kind) =>
                              bloc.add(WizardDocumentVerifyRequested(kind)),
                        ),
                        WizardStep.review => ReviewStep(draft: state.draft),
                      },
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      if (!state.isFirstStep) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: state.isBusy
                                ? null
                                : () => bloc.add(const WizardBackPressed()),
                            child: const Text('Back'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                      ],
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: state.isBusy
                              ? null
                              : () => bloc.add(
                                  state.isLastStep
                                      ? const WizardPublishPressed()
                                      : const WizardNextPressed(),
                                ),
                          child: state.submission == WizardSubmission.publishing
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  state.isLastStep
                                      ? (editing ? 'Save changes' : 'Publish')
                                      : 'Next',
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
