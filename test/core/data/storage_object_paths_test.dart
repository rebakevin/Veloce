import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/data/services/storage_object_paths.dart';
import 'package:veloce/core/domain/enums/storage_bucket.dart';

void main() {
  const paths = StorageObjectPaths();

  test('new paths are uuid/uuid.ext and never repeat', () {
    final first = paths.newPath('JPG');
    final second = paths.newPath('jpg');
    expect(first, matches(RegExp(r'^[0-9a-f-]{36}/[0-9a-f-]{36}\.jpg$')));
    expect(first, isNot(second));
  });

  test('the extension cannot smuggle path characters', () {
    expect(paths.newPath('../x'), endsWith('.x'));
  });

  test('a public url is split into bucket and path', () {
    final parsed = paths.parseUrl(
      'https://abc.supabase.co/storage/v1/object/public/car-media/a/b.jpg',
    );
    expect(parsed?.bucket, StorageBucket.carMedia);
    expect(parsed?.path, 'a/b.jpg');
  });

  test('unknown buckets and foreign urls are rejected', () {
    expect(paths.parseUrl('https://example.com/a.jpg'), isNull);
    expect(
      paths.parseUrl(
        'https://abc.supabase.co/storage/v1/object/public/other/a.jpg',
      ),
      isNull,
    );
  });
}
