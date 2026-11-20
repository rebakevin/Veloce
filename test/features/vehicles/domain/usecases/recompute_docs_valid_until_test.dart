import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/domain/entities/vehicle_document.dart';
import 'package:veloce/core/domain/enums/document_kind.dart';
import 'package:veloce/features/vehicles/domain/usecases/recompute_docs_valid_until.dart';

VehicleDocument _doc(DocumentKind kind, DateTime expiry) => VehicleDocument(
  kind: kind,
  vehicleId: 'car-1',
  number: 'N-1',
  expiry: expiry,
  photoUrl: 'https://files.test/a.jpg',
  verified: true,
);

void main() {
  const recompute = RecomputeDocsValidUntil();

  test('returns the earlier of insurance and medical expiry', () {
    final result = recompute([
      _doc(DocumentKind.insurance, DateTime(2027, 3, 1)),
      _doc(DocumentKind.medical, DateTime(2026, 12, 1)),
    ]);

    expect(result, DateTime(2026, 12, 1));
  });

  test('ignores the yellow paper', () {
    final result = recompute([
      _doc(DocumentKind.insurance, DateTime(2027, 3, 1)),
      _doc(DocumentKind.medical, DateTime(2027, 5, 1)),
      _doc(DocumentKind.yellowPaper, DateTime(2026, 1, 1)),
    ]);

    expect(result, DateTime(2027, 3, 1));
  });

  test('returns null while a required paper is missing', () {
    expect(
      recompute([_doc(DocumentKind.insurance, DateTime(2027, 3, 1))]),
      isNull,
    );
  });
}
