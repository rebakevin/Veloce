import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/domain/entities/vehicle_document.dart';
import 'package:veloce/core/domain/enums/document_kind.dart';
import 'package:veloce/core/domain/enums/vehicle_status.dart';
import 'package:veloce/features/vehicles/domain/rules/document_rules.dart';
import 'package:veloce/features/vehicles/domain/rules/document_status_rules.dart';

import '../builders.dart';

VehicleDocument _doc(DocumentKind kind, DateTime expiry) => VehicleDocument(
  kind: kind,
  vehicleId: 'car-1',
  number: 'N-1',
  expiry: expiry,
  photoUrl: 'https://files.test/a.jpg',
  verified: true,
);

void main() {
  final now = DateTime(2026, 11, 14, 15);

  group('DocumentRules.isValidOn', () {
    test('a paper is valid through its expiry day', () {
      expect(DocumentRules.isValidOn(DateTime(2026, 11, 14), now), isTrue);
    });

    test('a paper is expired the day after its expiry', () {
      expect(DocumentRules.isValidOn(DateTime(2026, 11, 13), now), isFalse);
    });
  });

  group('DocumentStatusRules', () {
    test('expiredRequired lists only lapsed required papers', () {
      final expired = DocumentStatusRules.expiredRequired([
        _doc(DocumentKind.insurance, DateTime(2026, 11, 1)),
        _doc(DocumentKind.medical, DateTime(2027, 1, 1)),
        _doc(DocumentKind.yellowPaper, DateTime(2026, 1, 1)),
      ], now: now);

      expect(expired, {DocumentKind.insurance});
    });

    test('statusAfter pauses when a required paper is missing', () {
      final status = DocumentStatusRules.statusAfter(
        [_doc(DocumentKind.insurance, DateTime(2027, 1, 1))],
        current: VehicleStatus.published,
        now: now,
      );

      expect(status, VehicleStatus.paused);
    });

    test('statusAfter keeps a paused car paused when papers are valid', () {
      final status = DocumentStatusRules.statusAfter(
        [
          _doc(DocumentKind.insurance, DateTime(2027, 1, 1)),
          _doc(DocumentKind.medical, DateTime(2027, 1, 1)),
        ],
        current: VehicleStatus.paused,
        now: now,
      );

      expect(status, VehicleStatus.paused);
    });

    test('a published car with lapsed papers needs pausing', () {
      final car = aVehicle(
        status: VehicleStatus.published,
        docsValidUntil: DateTime(2026, 11, 1),
      );

      expect(DocumentStatusRules.hasLapsed(car, now: now), isTrue);
      expect(DocumentStatusRules.needsPausing(car, now: now), isTrue);
    });

    test('a paused car with lapsed papers needs no pausing', () {
      final car = aVehicle(docsValidUntil: DateTime(2026, 11, 1));

      expect(DocumentStatusRules.hasLapsed(car, now: now), isTrue);
      expect(DocumentStatusRules.needsPausing(car, now: now), isFalse);
    });

    test('a car with valid or unknown papers has not lapsed', () {
      expect(
        DocumentStatusRules.hasLapsed(
          aVehicle(docsValidUntil: DateTime(2026, 11, 14)),
          now: now,
        ),
        isFalse,
      );
      expect(DocumentStatusRules.hasLapsed(aVehicle(), now: now), isFalse);
    });
  });
}
