import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/domain/enums/checklist_kind.dart';
import 'package:veloce/core/domain/enums/checklist_side.dart';
import 'package:veloce/core/domain/enums/media_type.dart';
import 'package:veloce/core/domain/enums/storage_bucket.dart';
import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/domain/services/media_storage.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/handover/presentation/bloc/checklist_cubit.dart';
import 'package:veloce/features/handover/presentation/bloc/checklist_state.dart';

void main() {
  late _FakeMediaStorage storage;

  setUp(() {
    storage = _FakeMediaStorage();
  });

  ChecklistCubit createCubit() {
    return ChecklistCubit(
      bookingId: 'booking-1',
      kind: ChecklistKind.pickup,
      side: ChecklistSide.owner,
      mediaStorage: storage,
      clock: _FakeClock(),
    );
  }

  final photoBytes = Uint8List.fromList([1, 2, 3]);

  blocTest<ChecklistCubit, ChecklistState>(
    'successful photo upload adds media and allows confirmation',
    build: () {
      storage.uploadResults.add(
        const Result<String>.success('https://example.com/photo.jpg'),
      );
      return createCubit();
    },
    act: (cubit) => cubit.uploadMedia(
      bytes: photoBytes,
      extension: 'jpg',
      mediaType: MediaType.photo,
    ),
    expect: () => [
      isA<ChecklistState>().having(
        (state) => state.isUploading,
        'uploading',
        true,
      ),
      isA<ChecklistState>()
          .having((state) => state.media.length, 'media count', 1)
          .having((state) => state.canConfirm, 'can confirm', true),
    ],
  );

  blocTest<ChecklistCubit, ChecklistState>(
    'failed upload can be retried successfully',
    build: () {
      storage.uploadResults.addAll([
        const Result<String>.failure(NetworkFailure()),
        const Result<String>.success('https://example.com/photo.jpg'),
      ]);
      return createCubit();
    },
    act: (cubit) async {
      await cubit.uploadMedia(
        bytes: photoBytes,
        extension: 'jpg',
        mediaType: MediaType.photo,
      );
      await cubit.retryUpload();
    },
    expect: () => [
      isA<ChecklistState>().having(
        (state) => state.isUploading,
        'uploading',
        true,
      ),
      isA<ChecklistState>()
          .having((state) => state.isUploading, 'uploading', false)
          .having((state) => state.errorMessage, 'error', isNotNull),
      isA<ChecklistState>().having(
        (state) => state.isUploading,
        'uploading',
        true,
      ),
      isA<ChecklistState>()
          .having((state) => state.media.length, 'media count', 1)
          .having((state) => state.errorMessage, 'error', isNull),
    ],
    verify: (_) {
      expect(storage.uploadCalls, 2);
    },
  );

  blocTest<ChecklistCubit, ChecklistState>(
    'video upload does not allow confirmation without a photo',
    build: () {
      storage.uploadResults.add(
        const Result<String>.success('https://example.com/video.mp4'),
      );
      return createCubit();
    },
    act: (cubit) => cubit.uploadMedia(
      bytes: photoBytes,
      extension: 'mp4',
      mediaType: MediaType.video,
    ),
    expect: () => [
      isA<ChecklistState>().having(
        (state) => state.isUploading,
        'uploading',
        true,
      ),
      isA<ChecklistState>()
          .having((state) => state.media.length, 'media count', 1)
          .having((state) => state.hasPhoto, 'has photo', false)
          .having((state) => state.canConfirm, 'can confirm', false),
    ],
  );

  blocTest<ChecklistCubit, ChecklistState>(
    'removing media removes it from the checklist',
    build: () {
      storage.uploadResults.add(
        const Result<String>.success('https://example.com/photo.jpg'),
      );
      return createCubit();
    },
    act: (cubit) async {
      await cubit.uploadMedia(
        bytes: photoBytes,
        extension: 'jpg',
        mediaType: MediaType.photo,
      );
      await cubit.removeMedia(cubit.state.media.single.id);
    },
    expect: () => [
      isA<ChecklistState>().having(
        (state) => state.isUploading,
        'uploading',
        true,
      ),
      isA<ChecklistState>().having(
        (state) => state.media.length,
        'media count',
        1,
      ),
      isA<ChecklistState>()
          .having((state) => state.media, 'media', isEmpty)
          .having((state) => state.canConfirm, 'can confirm', false),
    ],
    verify: (_) {
      expect(storage.deletedUrls, ['https://example.com/photo.jpg']);
    },
  );
}

class _FakeMediaStorage implements MediaStorage {
  final List<Result<String>> uploadResults = [];
  final List<String> deletedUrls = [];
  int uploadCalls = 0;

  @override
  Future<Result<String>> upload({
    required Uint8List bytes,
    required String extension,
    required StorageBucket bucket,
  }) async {
    uploadCalls++;
    return uploadResults.removeAt(0);
  }

  @override
  Future<Result<void>> delete(String url) async {
    deletedUrls.add(url);
    return const Result<void>.success(null);
  }
}

class _FakeClock implements Clock {
  @override
  DateTime now() => DateTime(2026, 11, 18);
}
