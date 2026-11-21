import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/domain/entities/checklist_entry.dart';
import '../../../../core/domain/entities/checklist_media.dart';
import '../../../../core/domain/enums/booking_actor.dart';
import '../../../../core/domain/enums/checklist_kind.dart';
import '../../../../core/domain/enums/checklist_side.dart';
import '../../../../core/domain/enums/media_type.dart';
import '../../../../core/domain/enums/storage_bucket.dart';
import '../../../../core/domain/services/clock.dart';
import '../../../../core/domain/services/media_storage.dart';
import '../../../../core/error/app_failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/repositories/handover_repository.dart';
import 'checklist_state.dart';

class ChecklistCubit extends Cubit<ChecklistState> {
  ChecklistCubit({
    required this.bookingId,
    required this.userId,
    required this.kind,
    required this.actor,
    required this.side,
    required this.startReturnFirst,
    required this._mediaStorage,
    required this._repository,
    required this._clock,
  }) : super(const ChecklistState());

  final String bookingId;
  final String userId;
  final ChecklistKind kind;
  final BookingActor actor;
  final ChecklistSide side;

  /// True when a return checklist is submitted while the booking is still
  /// `active`: the return is started first, then confirmed.
  final bool startReturnFirst;

  final MediaStorage _mediaStorage;
  final HandoverRepository _repository;
  final Clock _clock;
  final Uuid _uuid = const Uuid();

  _PendingUpload? _pendingUpload;

  /// Set once [HandoverRepository.startReturn] succeeded, so a retry after a
  /// failed confirm does not start the return a second time.
  bool _returnStarted = false;

  /// Loads what this side already saved (a partly ticked checklist).
  Future<void> load() async {
    final result = await _repository.loadChecklist(
      bookingId: bookingId,
      kind: kind,
      side: side,
    );
    if (isClosed) return;

    result.when(
      success: (saved) {
        final ticked = {
          for (final entry in saved.entries)
            if (entry.ticked && checklistItems.contains(entry.item)) entry.item,
        };

        // Anything the user did before the load finished wins.
        emit(
          state.copyWith(
            checkedItems: {...ticked, ...state.checkedItems},
            media: state.media.isEmpty ? saved.media : state.media,
          ),
        );
      },
      failure: (_) {},
    );
  }

  /// Same id for the same item, so a retried submit overwrites instead of
  /// adding duplicates.
  String _entryId(int index) => '${kind.key}_${side.key}_$index';

  List<String> get checklistItems {
    if (kind == ChecklistKind.pickup) {
      return const [
        'Exterior body condition',
        'Tires and wheels',
        'Lights, mirrors and windows',
        'Interior and seats',
        'Fuel level and odometer reading',
      ];
    }

    return const [
      'Exterior condition and new damage',
      'Tires and wheels',
      'Lights, mirrors and windows',
      'Interior cleanliness and condition',
      'Fuel level and odometer reading',
    ];
  }

  /// Saves the checklist, then confirms this side's pickup or return. The
  /// repository decides whether the other side has confirmed too.
  Future<void> submit() async {
    if (state.isSaving || !state.canConfirm) return;

    emit(
      state.copyWith(
        submitStatus: ChecklistSubmitStatus.saving,
        clearError: true,
      ),
    );

    try {
      final entries = [
        for (final (index, item) in checklistItems.indexed)
          ChecklistEntry(
            id: _entryId(index),
            bookingId: bookingId,
            kind: kind,
            side: side,
            item: item,
            ticked: state.checkedItems.contains(item),
            at: _clock.now(),
          ),
      ];

      final saved = await _repository.saveChecklist(
        bookingId: bookingId,
        kind: kind,
        side: side,
        entries: entries,
        media: state.media,
      );
      if (isClosed) return;

      final saveFailure = saved.when(success: (_) => null, failure: (f) => f);
      if (saveFailure != null) {
        _emitFailed(saveFailure.message);
        return;
      }

      final confirmed = await _confirm();
      if (isClosed) return;

      confirmed.when(
        success: (_) => emit(
          state.copyWith(
            submitStatus: ChecklistSubmitStatus.submitted,
            submitMessage: kind == ChecklistKind.pickup
                ? 'Pickup checklist submitted.'
                : 'Return checklist submitted.',
          ),
        ),
        failure: (failure) => _emitFailed(failure.message),
      );
    } catch (_) {
      if (isClosed) return;
      _emitFailed(const UnknownFailure().message);
    }
  }

  Future<Result<Object?>> _confirm() async {
    if (kind == ChecklistKind.pickup) {
      return _repository.confirmPickup(
        bookingId: bookingId,
        userId: userId,
        actor: actor,
      );
    }

    if (startReturnFirst && !_returnStarted) {
      final started = await _repository.startReturn(
        bookingId: bookingId,
        userId: userId,
        actor: actor,
      );
      final startFailure = started.when(
        success: (_) => null,
        failure: (f) => f,
      );
      if (startFailure != null) return Result.failure(startFailure);
      _returnStarted = true;
    }

    return _repository.confirmReturn(
      bookingId: bookingId,
      userId: userId,
      actor: actor,
    );
  }

  void _emitFailed(String message) {
    emit(
      state.copyWith(
        submitStatus: ChecklistSubmitStatus.failed,
        submitMessage: message,
      ),
    );
  }

  void toggleItem(String item) {
    if (!checklistItems.contains(item)) return;

    final updatedItems = Set<String>.from(state.checkedItems);

    if (updatedItems.contains(item)) {
      updatedItems.remove(item);
    } else {
      updatedItems.add(item);
    }

    emit(state.copyWith(checkedItems: updatedItems));
  }

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
            bookingId: bookingId,
            kind: kind,
            side: side,
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
