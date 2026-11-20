import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/domain/entities/vehicle_document.dart';
import 'package:veloce/core/domain/enums/document_kind.dart';
import 'package:veloce/features/vehicles/domain/rules/document_rules.dart';

VehicleDocument aVehicleDocument({
  DocumentKind kind = DocumentKind.insurance,
  DateTime? expiry,
}) {
  return VehicleDocument(
    kind: kind,
    vehicleId: 'car-1',
    number: 'N-1',
    expiry: expiry ?? DateTime(2027, 1, 1),
    photoUrl: 'https://example.com/doc.jpg',
    verified: true,
  );
}

void main() {
  final now = DateTime(2026, 11, 14);

  group('expiry', () {
    test('empty date returns an error message', () {
      expect(DocumentRules.expiry(null, now: now), isNotNull);
    });

    test('date in the past returns an error message', () {
      expect(DocumentRules.expiry(DateTime(2026, 11, 1), now: now), isNotNull);
    });

    test('date in the future returns no error', () {
      expect(DocumentRules.expiry(DateTime(2027, 1, 1), now: now), isNull);
    });
  });

  group('missingRequired', () {
    test('no documents lists insurance and medical', () {
      expect(DocumentRules.missingRequired([]), DocumentRules.requiredKinds);
    });

    test('insurance and medical present lists nothing', () {
      final documents = [
        aVehicleDocument(kind: DocumentKind.insurance),
        aVehicleDocument(kind: DocumentKind.medical),
      ];

      expect(DocumentRules.missingRequired(documents), isEmpty);
    });

    test('only insurance present lists medical', () {
      final documents = [aVehicleDocument(kind: DocumentKind.insurance)];

      expect(DocumentRules.missingRequired(documents), [DocumentKind.medical]);
    });
  });

  group('docsValidUntil', () {
    test('both documents present returns the earlier expiry', () {
      final documents = [
        aVehicleDocument(
          kind: DocumentKind.insurance,
          expiry: DateTime(2027, 6, 1),
        ),
        aVehicleDocument(
          kind: DocumentKind.medical,
          expiry: DateTime(2027, 3, 1),
        ),
      ];

      expect(DocumentRules.docsValidUntil(documents), DateTime(2027, 3, 1));
    });

    test('a required document missing returns null', () {
      final documents = [aVehicleDocument(kind: DocumentKind.insurance)];

      expect(DocumentRules.docsValidUntil(documents), isNull);
    });
  });
  group('plateMatches', () {
    test('same plate with different spacing and case returns no error', () {
      expect(DocumentRules.plateMatches('rab123a', 'RAB 123 A'), isNull);
    });

    test('different plate returns an error message', () {
      expect(DocumentRules.plateMatches('RAC 456 B', 'RAB 123 A'), isNotNull);
    });

    test('empty plate returns an error message', () {
      expect(DocumentRules.plateMatches('', 'RAB 123 A'), isNotNull);
    });
  });
}
