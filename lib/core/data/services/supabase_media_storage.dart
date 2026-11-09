import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/enums/storage_bucket.dart';
import '../../domain/services/media_storage.dart';
import '../../error/app_failure.dart';
import '../../error/result.dart';
import 'failure_mapper.dart';
import 'storage_object_paths.dart';

class SupabaseMediaStorage implements MediaStorage {
  SupabaseMediaStorage({
    required SupabaseClient client,
    this._paths = const StorageObjectPaths(),
  }) : _storage = client.storage;

  static const Duration _timeout = Duration(seconds: 60);

  final SupabaseStorageClient _storage;
  final StorageObjectPaths _paths;

  @override
  Future<Result<String>> upload({
    required Uint8List bytes,
    required String extension,
    required StorageBucket bucket,
  }) async {
    final path = _paths.newPath(extension);
    try {
      final files = _storage.from(bucket.key);
      await files.uploadBinary(path, bytes).timeout(_timeout);
      return Result.success(files.getPublicUrl(path));
    } on Object catch (error, stackTrace) {
      return Result.failure(mapToFailure(error, stackTrace));
    }
  }

  @override
  Future<Result<void>> delete(String url) async {
    final target = _paths.parseUrl(url);
    if (target == null) {
      return const Result.failure(ValidationFailure('Unknown file address.'));
    }
    try {
      await _storage
          .from(target.bucket.key)
          .remove([target.path])
          .timeout(_timeout);
      return const Result.success(null);
    } on Object catch (error, stackTrace) {
      return Result.failure(mapToFailure(error, stackTrace));
    }
  }
}
