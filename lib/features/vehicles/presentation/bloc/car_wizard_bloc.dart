import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:veloce/core/domain/enums/document_kind.dart';
import 'package:veloce/core/domain/services/pricing_calculator.dart';
import 'package:veloce/core/error/result.dart';

import '../../domain/entities/wizard_draft.dart';
import '../../domain/entities/wizard_step.dart';
import '../../domain/rules/wizard_step_rules.dart';
import '../../domain/usecases/load_vehicle_draft.dart';
import '../../domain/usecases/publish_vehicle.dart';
import '../../domain/usecases/update_vehicle.dart';
import '../../domain/usecases/verify_document.dart';

part 'car_wizard_event.dart';
part 'car_wizard_state.dart';

class CarWizardBloc extends Bloc<CarWizardEvent, CarWizardState> {
  CarWizardBloc({
    required this._verifyDocument,
    required this._publishVehicle,
    required this._updateVehicle,
    required this._loadVehicleDraft,
    this._calculator = const PricingCalculator(),
  }) : super(const CarWizardState()) {
    on<WizardDraftChanged>(_onDraftChanged);
    on<WizardNextPressed>(_onNextPressed);
    on<WizardBackPressed>(_onBackPressed);
    on<WizardDocumentVerifyRequested>(_onVerifyRequested);
    on<WizardPublishPressed>(_onPublishPressed);
    on<WizardEditStarted>(_onEditStarted);
  }

  final VerifyDocument _verifyDocument;
  final PublishVehicle _publishVehicle;
  final UpdateVehicle _updateVehicle;
  final LoadVehicleDraft _loadVehicleDraft;
  final PricingCalculator _calculator;

  void _onDraftChanged(WizardDraftChanged event, Emitter<CarWizardState> emit) {
    final errors = state.errors.isEmpty
        ? const <WizardField, String>{}
        : WizardStepRules.validate(
            state.step,
            event.draft,
            calculator: _calculator,
          );
    emit(CarWizardState(step: state.step, draft: event.draft, errors: errors));
  }

  void _onNextPressed(WizardNextPressed event, Emitter<CarWizardState> emit) {
    final errors = WizardStepRules.validate(
      state.step,
      state.draft,
      calculator: _calculator,
    );
    if (errors.isNotEmpty) {
      emit(
        CarWizardState(step: state.step, draft: state.draft, errors: errors),
      );
      return;
    }
    if (state.isLastStep) return;
    emit(
      CarWizardState(
        step: state.steps[state.steps.indexOf(state.step) + 1],
        draft: state.draft,
      ),
    );
  }

  void _onBackPressed(WizardBackPressed event, Emitter<CarWizardState> emit) {
    if (state.isFirstStep) return;
    emit(
      CarWizardState(
        step: state.steps[state.steps.indexOf(state.step) - 1],
        draft: state.draft,
      ),
    );
  }

  Future<void> _onVerifyRequested(
    WizardDocumentVerifyRequested event,
    Emitter<CarWizardState> emit,
  ) async {
    final document = state.draft.documents[event.kind];
    if (state.isBusy || document == null) return;
    emit(
      CarWizardState(
        step: state.step,
        draft: state.draft,
        errors: state.errors,
        verifying: event.kind,
      ),
    );
    final result = await _verifyDocument(document.number);
    if (isClosed) return;

    final field = WizardStepRules.documentFields[event.kind]!;
    final documents = {...state.draft.documents};
    final errors = {...state.errors};
    switch (result) {
      case Success():
        documents[event.kind] = document.copyWith(verified: true);
        errors.remove(field);
      case Failure(:final failure):
        errors[field] = failure.message;
    }
    emit(
      CarWizardState(
        step: state.step,
        draft: state.draft.copyWith(documents: documents),
        errors: errors,
      ),
    );
  }

  Future<void> _onPublishPressed(
    WizardPublishPressed event,
    Emitter<CarWizardState> emit,
  ) async {
    if (state.isBusy || !state.isLastStep) return;
    emit(
      CarWizardState(
        step: state.step,
        draft: state.draft,
        submission: WizardSubmission.publishing,
      ),
    );
    final draft = state.draft;
    final Result<String> result = draft.isEditing
        ? (await _updateVehicle(draft)).when(
            success: (_) => Result.success(draft.vehicleId!),
            failure: Result.failure,
          )
        : await _publishVehicle(draft);
    if (isClosed) return;
    switch (result) {
      case Success(:final value):
        emit(
          CarWizardState(
            step: state.step,
            draft: state.draft,
            submission: WizardSubmission.published,
            publishedId: value,
          ),
        );
      case Failure(:final failure):
        emit(
          CarWizardState(
            step: state.step,
            draft: state.draft,
            submission: WizardSubmission.failure,
            message: failure.message,
          ),
        );
    }
  }

  Future<void> _onEditStarted(
    WizardEditStarted event,
    Emitter<CarWizardState> emit,
  ) async {
    if (state.isBusy) return;
    emit(const CarWizardState(submission: WizardSubmission.loading));
    final result = await _loadVehicleDraft(event.vehicleId);
    if (isClosed) return;
    switch (result) {
      case Success(:final value):
        emit(CarWizardState(draft: value));
      case Failure(:final failure):
        emit(
          CarWizardState(
            submission: WizardSubmission.loadFailure,
            message: failure.message,
          ),
        );
    }
  }
}
