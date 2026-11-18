import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:veloce/core/domain/services/pricing_calculator.dart';

import '../../domain/entities/wizard_draft.dart';
import '../../domain/entities/wizard_step.dart';
import '../../domain/rules/wizard_step_rules.dart';

part 'car_wizard_event.dart';
part 'car_wizard_state.dart';

class CarWizardBloc extends Bloc<CarWizardEvent, CarWizardState> {
  CarWizardBloc({this._calculator = const PricingCalculator()})
    : super(const CarWizardState()) {
    on<WizardDraftChanged>(_onDraftChanged);
    on<WizardNextPressed>(_onNextPressed);
    on<WizardBackPressed>(_onBackPressed);
  }

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
        step: WizardStep.values[state.step.index + 1],
        draft: state.draft,
      ),
    );
  }

  void _onBackPressed(WizardBackPressed event, Emitter<CarWizardState> emit) {
    if (state.isFirstStep) return;
    emit(
      CarWizardState(
        step: WizardStep.values[state.step.index - 1],
        draft: state.draft,
      ),
    );
  }
}
