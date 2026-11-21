import 'package:veloce/core/domain/enums/document_kind.dart';
import 'package:veloce/core/domain/services/pricing_calculator.dart';
import 'package:veloce/core/validation/validators.dart';

import '../entities/wizard_draft.dart';
import '../entities/wizard_step.dart';
import 'document_rules.dart';

enum WizardField {
  photos,
  plate,
  make,
  model,
  year,
  type,
  neighbourhood,
  description,
  transmission,
  fuel,
  seats,
  dailyPrice,
  longRates,
  cautionFee,
  fuelRule,
  smoking,
  documentInsurance,
  documentMedical,
  documentYellowPaper,
}

abstract final class WizardStepRules {
  static const int minPhotos = 3;
  static const int maxPhotos = 6;
  static const int minSeats = 2;
  static const int maxSeats = 9;

  static const Map<DocumentKind, WizardField> documentFields = {
    DocumentKind.insurance: WizardField.documentInsurance,
    DocumentKind.medical: WizardField.documentMedical,
    DocumentKind.yellowPaper: WizardField.documentYellowPaper,
  };

  static Map<WizardField, String> validate(
    WizardStep step,
    WizardDraft draft, {
    PricingCalculator calculator = const PricingCalculator(),
    DateTime? now,
  }) {
    final at = now ?? DateTime.now();
    return switch (step) {
      WizardStep.media => _media(draft),
      WizardStep.details => _details(draft),
      WizardStep.specs => _specs(draft),
      WizardStep.pricing => _pricing(draft, calculator),
      WizardStep.rules => _rules(draft),
      WizardStep.documents => _documents(draft, at),
      WizardStep.review => {
        for (final earlier in WizardStep.values.take(
          WizardStep.documents.index,
        ))
          ...validate(earlier, draft, calculator: calculator, now: at),
      },
    };
  }

  static String? documentProblem(
    WizardDraft draft,
    DocumentKind kind,
    DateTime now,
  ) {
    final document = draft.documents[kind];
    if (document == null || document.photo == null) {
      return 'Add a photo of the ${kind.label.toLowerCase()}.';
    }
    return Validators.requiredText(document.number, field: 'Document number') ??
        DocumentRules.plateMatches(document.plate, draft.plate) ??
        DocumentRules.expiry(document.expiry, now: now) ??
        (document.verified ? null : 'Verify this document.');
  }

  static Map<WizardField, String> _media(WizardDraft draft) {
    final count = draft.photoCount;
    return _collect({
      WizardField.photos: count < minPhotos || count > maxPhotos
          ? 'Add $minPhotos to $maxPhotos photos.'
          : null,
    });
  }

  static Map<WizardField, String> _details(WizardDraft draft) {
    return _collect({
      WizardField.plate: Validators.plate(draft.plate),
      WizardField.make: Validators.requiredText(draft.make, field: 'Make'),
      WizardField.model: Validators.requiredText(draft.model, field: 'Model'),
      WizardField.year: Validators.vehicleYear(draft.year),
      WizardField.type: draft.type == null ? 'Choose the car type.' : null,
      WizardField.neighbourhood: Validators.requiredText(
        draft.neighbourhood,
        field: 'Pickup neighbourhood',
      ),
      WizardField.description: Validators.requiredText(
        draft.description,
        field: 'Description',
      ),
    });
  }

  static Map<WizardField, String> _specs(WizardDraft draft) {
    final seats = draft.seats;
    return _collect({
      WizardField.transmission: draft.transmission == null
          ? 'Choose the transmission.'
          : null,
      WizardField.fuel: draft.fuel == null ? 'Choose the fuel type.' : null,
      WizardField.seats: seats == null
          ? 'Enter the number of seats.'
          : seats < minSeats || seats > maxSeats
          ? 'Seats must be $minSeats to $maxSeats.'
          : null,
    });
  }

  static Map<WizardField, String> _pricing(
    WizardDraft draft,
    PricingCalculator calculator,
  ) {
    final dailyPrice = draft.dailyPrice;
    final dailyError = Validators.dailyPrice(dailyPrice);
    return _collect({
      WizardField.dailyPrice: dailyError,
      WizardField.longRates: dailyError == null
          ? calculator.validateLongRates(
              dailyPrice: dailyPrice!,
              longRates: draft.longRates,
            )
          : null,
      WizardField.cautionFee: Validators.cautionFee(draft.cautionFee),
    });
  }

  static Map<WizardField, String> _rules(WizardDraft draft) {
    return _collect({
      WizardField.fuelRule: Validators.requiredText(
        draft.fuelRule,
        field: 'Fuel rule',
      ),
      WizardField.smoking: Validators.requiredText(
        draft.smoking,
        field: 'Smoking rule',
      ),
    });
  }

  static Map<WizardField, String> _documents(WizardDraft draft, DateTime now) {
    final errors = <WizardField, String>{};
    for (final kind in DocumentKind.values) {
      final isRequired = DocumentRules.requiredKinds.contains(kind);
      final hasPhoto = draft.documents[kind]?.photo != null;
      if (!isRequired && !hasPhoto) continue;
      final problem = documentProblem(draft, kind, now);
      if (problem != null) errors[documentFields[kind]!] = problem;
    }
    return errors;
  }

  static Map<WizardField, String> _collect(Map<WizardField, String?> checks) {
    return {
      for (final entry in checks.entries)
        if (entry.value != null) entry.key: entry.value!,
    };
  }
}
