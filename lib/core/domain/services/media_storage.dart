import 'dart:typed_data';

import '../../error/result.dart';
import '../enums/storage_bucket.dart';

/// File storage for photos, videos and documents. Every feature uploads through
/// this contract; only the Supabase adapter knows the SDK.
abstract interface class MediaStorage {
  /// Uploads [bytes] under a generated `uuid/uuid.ext` path and returns the URL.
  /// Compress images before calling (`image_picker` `imageQuality: 80`).
  Future<Result<String>> upload({
    required Uint8List bytes,
    required String extension,
    required StorageBucket bucket,
  });

  /// Best effort: the anon role has no delete policy (TECHNICAL.md §7), so a
  /// file may remain. Replacing a file means uploading a new path.
  Future<Result<void>> delete(String url);
}
