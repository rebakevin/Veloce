import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/domain/entities/checklist_media.dart';
import '../../../../core/domain/enums/checklist_kind.dart';
import '../../../../core/domain/enums/checklist_side.dart';
import '../../../../core/domain/enums/media_type.dart';
import '../../../../core/domain/enums/storage_bucket.dart';
import '../../../../core/domain/services/clock.dart';
import '../../../../core/domain/services/media_storage.dart';
import '../../../../core/error/app_failure.dart';
import 'checklist_state.dart';

class ChecklistCubit extends Cubit<ChecklistState> {
  ChecklistCubit({
    required String bookingId,
    required ChecklistKind kind,
    required ChecklistSide side,
    required MediaStorage mediaStorage,
    required Clock clock,
  }) : this._(bookingId, kind, side, mediaStorage, clock);

  ChecklistCubit._(
    this._bookingId,
    this._kind,
    this._side,
    this._mediaStorage,
    this._clock,
  ) : super(const ChecklistState());

  final String _bookingId;
  final ChecklistKind _kind;
  final ChecklistSide _side;
  final MediaStorage _mediaStorage;
  final Clock _clock;
  final Uuid _uuid = const Uuid();

  _PendingUpload? _pendingUpload;

  Future<void> uploadMedia({
    required Uint8List bytes,
    required String extension,
    required MediaType mediaType,
  }) async {
    if (state.isUploading) return;

    final upload = _PendingUpload(
      bytes: Uint8List.fromList(bytes),
      extension: extension,
      mediaType: mediaType,
    );

    _pendingUpload = upload;
    await _upload(upload);
  }

  Future<void> retryUpload() async {
    final upload = _pendingUpload;

    if (upload == null || state.isUploading) return;

    await _upload(upload);
  }

  Future<void> _upload(_PendingUpload upload) async {
    emit(state.copyWith(isUploading: true, clearError: true));

    try {
      final result = await _mediaStorage.upload(
        bytes: upload.bytes,
        extension: upload.extension,
        bucket: StorageBucket.checklistMedia,
      );

      if (isClosed) return;

      result.when(
        success: (url) {
          final item = ChecklistMedia(
            id: _uuid.v4(),
            bookingId: _bookingId,
            kind: _kind,
            side: _side,
            mediaType: upload.mediaType,
            url: url,
            at: _clock.now(),
          );

          _pendingUpload = null;

          emit(
            state.copyWith(
              media: [...state.media, item],
              isUploading: false,
              clearError: true,
            ),
          );
        },
        failure: (failure) {
          emit(
            state.copyWith(isUploading: false, errorMessage: failure.message),
          );
        },
      );
    } catch (_) {
      if (isClosed) return;

      emit(
        state.copyWith(
          isUploading: false,
          errorMessage: const UnknownFailure().message,
        ),
      );
    }
  }

  Future<void> removeMedia(String mediaId) async {
    final item = state.media.where((media) => media.id == mediaId);

    if (item.isEmpty) return;

    final removedMedia = item.first;

    emit(
      state.copyWith(
        media: state.media.where((media) => media.id != mediaId).toList(),
        clearError: true,
      ),
    );

    final result = await _mediaStorage.delete(removedMedia.url);

    if (isClosed) return;

    result.when(
      success: (_) {},
      failure: (_) {
        emit(
          state.copyWith(
            errorMessage: 'Media was removed from the checklist, but its stored file could not be deleted.',
          ),
        );
      },
    );
  }
}

class _PendingUpload {
  const _PendingUpload({
    required this.bytes,
    required this.extension,
    required this.mediaType,
  });

  final Uint8List bytes;
  final String extension;
  final MediaType mediaType;
}
