import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/domain/entities/long_rate.dart';
import 'package:veloce/core/domain/enums/document_kind.dart';
import 'package:veloce/features/vehicles/domain/entities/wizard_draft.dart';
import 'package:veloce/features/vehicles/domain/entities/wizard_step.dart';
import 'package:veloce/features/vehicles/domain/rules/wizard_step_rules.dart';

import '../builders.dart';

void main() {
  group('media step', () {
    test('two photos returns a photos error', () {
      final draft = aWizardDraft().copyWith(photos: somePhotos(2));

      final errors = WizardStepRules.validate(WizardStep.media, draft);

      expect(errors.keys, [WizardField.photos]);
    });

    test('three photos returns no errors', () {
      final errors = WizardStepRules.validate(WizardStep.media, aWizardDraft());

      expect(errors, isEmpty);
    });

    test('seven photos returns a photos error', () {
      final draft = aWizardDraft().copyWith(photos: somePhotos(7));

      final errors = WizardStepRules.validate(WizardStep.media, draft);

      expect(errors.keys, [WizardField.photos]);
    });
  });

  group('details step', () {
    test('a wrong plate returns only a plate error', () {
      final draft = aWizardDraft().copyWith(plate: '123');

      final errors = WizardStepRules.validate(WizardStep.details, draft);

      expect(errors.keys, [WizardField.plate]);
    });

    test('a complete step returns no errors', () {
      final errors = WizardStepRules.validate(
        WizardStep.details,
        aWizardDraft(),
      );

      expect(errors, isEmpty);
    });
  });

  group('specs step', () {
    test('twelve seats returns a seats error', () {
      final draft = aWizardDraft().copyWith(seats: 12);

      final errors = WizardStepRules.validate(WizardStep.specs, draft);

      expect(errors.keys, [WizardField.seats]);
    });
  });

  group('pricing step', () {
    test('a tier priced above the daily price returns a tiers error', () {
      final draft = aWizardDraft().copyWith(
        longRates: const [LongRate(fromDays: 3, pricePerDay: 60000)],
      );

      final errors = WizardStepRules.validate(WizardStep.pricing, draft);

      expect(errors.keys, [WizardField.longRates]);
    });

    test('a daily price below the minimum skips the tiers check', () {
      final draft = aWizardDraft().copyWith(dailyPrice: 4000);

      final errors = WizardStepRules.validate(WizardStep.pricing, draft);

      expect(errors.keys, [WizardField.dailyPrice]);
    });
  });

  group('review step', () {
    test('a blank make from an earlier step is reported', () {
      final draft = aWizardDraft().copyWith(make: '');

      final errors = WizardStepRules.validate(WizardStep.review, draft);

      expect(errors.keys, [WizardField.make]);
    });

    test('a complete draft returns no errors', () {
      final errors = WizardStepRules.validate(
        WizardStep.review,
        aWizardDraft(),
      );

      expect(errors, isEmpty);
    });
  });
  group('documents step', () {
    DraftDocument goodDocument() => DraftDocument(
      photo: somePhotos(1).first,
      number: 'N-1',
      plate: 'RAB 123 A',
      expiry: DateTime(2099),
      verified: true,
    );

    test('no documents returns insurance and medical errors', () {
      final errors = WizardStepRules.validate(
        WizardStep.documents,
        aWizardDraft(),
      );

      expect(errors.keys, [
        WizardField.documentInsurance,
        WizardField.documentMedical,
      ]);
    });

    test('both required documents and no yellow paper returns no errors', () {
      final draft = aWizardDraft().copyWith(
        documents: {
          DocumentKind.insurance: goodDocument(),
          DocumentKind.medical: goodDocument(),
        },
      );

      final errors = WizardStepRules.validate(WizardStep.documents, draft);

      expect(errors, isEmpty);
    });

    test('a document with another plate returns an error', () {
      final draft = aWizardDraft().copyWith(
        documents: {
          DocumentKind.insurance: goodDocument().copyWith(plate: 'RAC 456 B'),
          DocumentKind.medical: goodDocument(),
        },
      );

      final errors = WizardStepRules.validate(WizardStep.documents, draft);

      expect(errors.keys, [WizardField.documentInsurance]);
    });

    test('a yellow paper with a photo but no number returns an error', () {
      final draft = aWizardDraft().copyWith(
        documents: {
          DocumentKind.insurance: goodDocument(),
          DocumentKind.medical: goodDocument(),
          DocumentKind.yellowPaper: goodDocument().copyWith(number: ''),
        },
      );

      final errors = WizardStepRules.validate(WizardStep.documents, draft);

      expect(errors.keys, [WizardField.documentYellowPaper]);
    });
  });
}
