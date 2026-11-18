import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/features/vehicles/domain/entities/wizard_step.dart';
import 'package:veloce/features/vehicles/domain/rules/wizard_step_rules.dart';
import 'package:veloce/features/vehicles/presentation/bloc/car_wizard_bloc.dart';

import '../../domain/builders.dart';

void main() {
  group('CarWizardBloc next', () {
    blocTest<CarWizardBloc, CarWizardState>(
      'next with an invalid step shows the errors and stays',
      build: CarWizardBloc.new,
      act: (bloc) => bloc.add(const WizardNextPressed()),
      expect: () => [
        isA<CarWizardState>()
            .having((s) => s.step, 'step', WizardStep.media)
            .having((s) => s.errors.keys, 'errors', [WizardField.photos]),
      ],
    );

    blocTest<CarWizardBloc, CarWizardState>(
      'next with a valid step moves to the next step',
      build: CarWizardBloc.new,
      seed: () => CarWizardState(draft: aWizardDraft()),
      act: (bloc) => bloc.add(const WizardNextPressed()),
      expect: () => [
        CarWizardState(step: WizardStep.details, draft: aWizardDraft()),
      ],
    );

    blocTest<CarWizardBloc, CarWizardState>(
      'next on the last step does nothing',
      build: CarWizardBloc.new,
      seed: () =>
          CarWizardState(step: WizardStep.review, draft: aWizardDraft()),
      act: (bloc) => bloc.add(const WizardNextPressed()),
      expect: () => <CarWizardState>[],
    );
  });

  group('CarWizardBloc back', () {
    blocTest<CarWizardBloc, CarWizardState>(
      'back moves to the previous step',
      build: CarWizardBloc.new,
      seed: () =>
          CarWizardState(step: WizardStep.details, draft: aWizardDraft()),
      act: (bloc) => bloc.add(const WizardBackPressed()),
      expect: () => [CarWizardState(draft: aWizardDraft())],
    );

    blocTest<CarWizardBloc, CarWizardState>(
      'back on the first step does nothing',
      build: CarWizardBloc.new,
      act: (bloc) => bloc.add(const WizardBackPressed()),
      expect: () => <CarWizardState>[],
    );
  });

  group('CarWizardBloc draft changes', () {
    blocTest<CarWizardBloc, CarWizardState>(
      'fixing the draft after an error clears the error',
      build: CarWizardBloc.new,
      seed: () => const CarWizardState(
        errors: {WizardField.photos: 'Add 3 to 6 photos.'},
      ),
      act: (bloc) => bloc.add(WizardDraftChanged(aWizardDraft())),
      expect: () => [CarWizardState(draft: aWizardDraft())],
    );

    blocTest<CarWizardBloc, CarWizardState>(
      'a change before any error does not validate',
      build: CarWizardBloc.new,
      act: (bloc) => bloc.add(WizardDraftChanged(aWizardDraft())),
      expect: () => [CarWizardState(draft: aWizardDraft())],
    );
  });
}
