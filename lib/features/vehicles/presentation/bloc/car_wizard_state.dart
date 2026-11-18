part of 'car_wizard_bloc.dart';

class CarWizardState extends Equatable {
  const CarWizardState({
    this.step = WizardStep.media,
    this.draft = const WizardDraft(),
    this.errors = const {},
  });

  final WizardStep step;
  final WizardDraft draft;
  final Map<WizardField, String> errors;

  bool get isFirstStep => step == WizardStep.values.first;

  bool get isLastStep => step == WizardStep.values.last;

  @override
  List<Object?> get props => [step, draft, errors];
}
