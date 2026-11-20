part of 'car_wizard_bloc.dart';

sealed class CarWizardEvent extends Equatable {
  const CarWizardEvent();

  @override
  List<Object?> get props => [];
}

final class WizardDraftChanged extends CarWizardEvent {
  const WizardDraftChanged(this.draft);

  final WizardDraft draft;

  @override
  List<Object?> get props => [draft];
}

final class WizardNextPressed extends CarWizardEvent {
  const WizardNextPressed();
}

final class WizardBackPressed extends CarWizardEvent {
  const WizardBackPressed();
}

final class WizardDocumentVerifyRequested extends CarWizardEvent {
  const WizardDocumentVerifyRequested(this.kind);

  final DocumentKind kind;

  @override
  List<Object?> get props => [kind];
}

final class WizardPublishPressed extends CarWizardEvent {
  const WizardPublishPressed();
}
