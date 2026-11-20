import 'dart:typed_data';

import 'package:mocktail/mocktail.dart';
import 'package:veloce/core/domain/enums/storage_bucket.dart';
import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/domain/services/media_storage.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/handover/domain/repositories/handover_repository.dart';
import 'package:veloce/features/handover/domain/repositories/repair_expense_repository.dart';

class MockHandoverRepository extends Mock implements HandoverRepository {}

class MockRepairExpenseRepository extends Mock
    implements RepairExpenseRepository {}

/// Succeeds with a fixed URL for every upload.
class FakeMediaStorage implements MediaStorage {
  @override
  Future<Result<String>> upload({
    required Uint8List bytes,
    required String extension,
    required StorageBucket bucket,
  }) async => const Result.success('https://example.com/photo.jpg');

  @override
  Future<Result<void>> delete(String url) async =>
      const Result<void>.success(null);
}

class FixedClock implements Clock {
  @override
  DateTime now() => DateTime(2026, 11, 18);
}
