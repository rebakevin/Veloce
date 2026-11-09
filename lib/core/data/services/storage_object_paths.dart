import 'package:uuid/uuid.dart';

import '../../domain/enums/storage_bucket.dart';

/// Builds unguessable object paths and reads them back from public URLs.
class StorageObjectPaths {
  const StorageObjectPaths({this._uuid = const Uuid()});

  final Uuid _uuid;

  /// `uuid/uuid.ext`, never derived from user input.
  String newPath(String extension) {
    final cleaned = extension
        .replaceAll(RegExp('[^A-Za-z0-9]'), '')
        .toLowerCase();
    return '${_uuid.v4()}/${_uuid.v4()}.$cleaned';
  }

  /// Splits `.../storage/v1/object/public/<bucket>/<path>` into its parts, or
  /// returns `null` when [url] is not a Supabase public URL for a known bucket.
  ({StorageBucket bucket, String path})? parseUrl(String url) {
    const marker = '/storage/v1/object/public/';
    final start = url.indexOf(marker);
    if (start < 0) return null;
    final rest = url.substring(start + marker.length);
    final slash = rest.indexOf('/');
    if (slash <= 0) return null;
    final bucketKey = rest.substring(0, slash);
    final bucket = StorageBucket.values
        .where((candidate) => candidate.key == bucketKey)
        .firstOrNull;
    if (bucket == null) return null;
    return (bucket: bucket, path: rest.substring(slash + 1));
  }
}
