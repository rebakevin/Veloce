import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/domain/entities/document_photo.dart';
import 'package:veloce/core/domain/entities/vehicle_photo.dart';
import 'package:veloce/features/vehicles/domain/entities/wizard_draft.dart';

DocumentPhoto _photo(int tag) =>
    DocumentPhoto(bytes: Uint8List.fromList([tag]), extension: 'jpg');

VehiclePhoto _kept(String id) => VehiclePhoto(
  id: id,
  vehicleId: 'car-1',
  url: 'https://files.test/$id.jpg',
  order: 0,
  isPrimary: false,
);

void main() {
  group('WizardDraft.movePhoto', () {
    final fresh = WizardDraft(photos: [_photo(1), _photo(2), _photo(3)]);

    test('moves a new photo later', () {
      final moved = fresh.movePhoto(0, 1);

      expect(moved.photos, [_photo(2), _photo(1), _photo(3)]);
    });

    test('moves a new photo earlier', () {
      final moved = fresh.movePhoto(2, -1);

      expect(moved.photos, [_photo(1), _photo(3), _photo(2)]);
    });

    test('the main photo follows its photo when moved', () {
      final moved = fresh.copyWith(primaryIndex: 0).movePhoto(0, 1);

      expect(moved.primaryIndex, 1);
    });

    test('the main photo follows when another photo swaps past it', () {
      final moved = fresh.copyWith(primaryIndex: 1).movePhoto(0, 1);

      expect(moved.primaryIndex, 0);
    });

    test(
      'the first photo cannot move earlier and the last cannot move later',
      () {
        expect(fresh.canMovePhoto(0, -1), isFalse);
        expect(fresh.canMovePhoto(2, 1), isFalse);
        expect(fresh.movePhoto(0, -1), fresh);
      },
    );

    test('kept photos reorder among themselves', () {
      final edit = WizardDraft(
        vehicleId: 'car-1',
        keptPhotos: [_kept('a'), _kept('b')],
        photos: [_photo(1)],
      );

      expect(edit.movePhoto(1, -1).keptPhotos.map((p) => p.id), ['b', 'a']);
    });

    test('a new photo cannot move in front of kept photos', () {
      final edit = WizardDraft(
        vehicleId: 'car-1',
        keptPhotos: [_kept('a')],
        photos: [_photo(1)],
      );

      expect(edit.canMovePhoto(1, -1), isFalse);
      expect(edit.canMovePhoto(0, 1), isFalse);
    });
  });
}
