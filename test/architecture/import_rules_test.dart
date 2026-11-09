import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Enforces docs/code-conventions/architecture.md on every import in `lib/`.
void main() {
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList();

  final sdkImport = RegExp(
    r"import 'package:(cloud_firestore|firebase_auth|supabase_flutter)/",
  );
  final featureImport = RegExp(
    r"(?:import|export) 'package:veloce/features/(\w+)/([^']+)'",
  );

  String read(File file) => file.readAsStringSync();

  bool inLayer(File file, String layer) => file.path.contains('/$layer/');

  test('presentation never imports a backend SDK', () {
    final offenders = files
        .where(
          (file) =>
              inLayer(file, 'presentation') ||
              file.path.contains('lib/core/widgets/'),
        )
        .where((file) => sdkImport.hasMatch(read(file)))
        .map((file) => file.path);
    expect(offenders, isEmpty);
  });

  test('domain stays pure Dart', () {
    final offenders = files
        .where((file) => inLayer(file, 'domain'))
        .where((file) {
          final source = read(file);
          return sdkImport.hasMatch(source) ||
              source.contains("import 'package:flutter/");
        })
        .map((file) => file.path);
    expect(offenders, isEmpty);
  });

  test('cubits and blocs never import a backend SDK', () {
    final offenders = files
        .where((file) => inLayer(file, 'bloc'))
        .where((file) => sdkImport.hasMatch(read(file)))
        .map((file) => file.path);
    expect(offenders, isEmpty);
  });

  test('features reach other features only through their barrel', () {
    final offenders = <String>[];
    for (final file in files.where(
      (file) => file.path.contains('lib/features/'),
    )) {
      final ownFeature = RegExp(r'lib/features/(\w+)/')
          .firstMatch(file.path)!
          .group(1);
      for (final match in featureImport.allMatches(read(file))) {
        final feature = match.group(1);
        final target = match.group(2)!;
        if (feature != ownFeature && target != '$feature.dart') {
          offenders.add('${file.path} -> $feature/$target');
        }
      }
    }
    expect(offenders, isEmpty);
  });

  test('setState is never used', () {
    final offenders = files
        .where((file) => read(file).contains('setState('))
        .map((file) => file.path);
    expect(offenders, isEmpty);
  });
}
