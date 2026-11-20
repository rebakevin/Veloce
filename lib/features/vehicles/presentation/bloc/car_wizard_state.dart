part of 'car_wizard_bloc.dart';

enum WizardSubmission { idle, publishing, published, failure }

class CarWizardState extends Equatable {
  const CarWizardState({
    this.step = WizardStep.media,
    this.draft = const WizardDraft(),
    this.errors = const {},
    this.verifying,
    this.submission = WizardSubmission.idle,
    this.message,
    this.publishedId,
  });

  final WizardStep step;
  final WizardDraft draft;
  final Map<WizardField, String> errors;
  final DocumentKind? verifying;
  final WizardSubmission submission;
  final String? message;
  final String? publishedId;

  bool get isFirstStep => step == WizardStep.values.first;

  bool get isLastStep => step == WizardStep.values.last;

  bool get isBusy =>
      verifying != null || submission == WizardSubmission.publishing;

  @override
  List<Object?> get props => [
    step,
    draft,
    errors,
    verifying,
    submission,
    message,
    publishedId,
  ];
}
