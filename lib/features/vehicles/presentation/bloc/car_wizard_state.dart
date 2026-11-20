part of 'car_wizard_bloc.dart';

enum WizardSubmission {
  idle,
  loading,
  loadFailure,
  publishing,
  published,
  failure,
}

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

  /// Edit mode skips the documents step: documents have their own screen.
  List<WizardStep> get steps => [
    for (final s in WizardStep.values)
      if (!(draft.isEditing && s == WizardStep.documents)) s,
  ];

  bool get isFirstStep => step == steps.first;

  bool get isLastStep => step == steps.last;

  bool get isBusy =>
      verifying != null ||
      submission == WizardSubmission.loading ||
      submission == WizardSubmission.publishing;

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
