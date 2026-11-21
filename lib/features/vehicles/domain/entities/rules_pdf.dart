import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// The optional rental-rules PDF picked in the wizard, waiting to be uploaded.
class RulesPdf extends Equatable {
  const RulesPdf({required this.bytes, required this.name});

  /// Largest PDF the wizard accepts.
  static const int maxBytes = 5 * 1024 * 1024;

  /// Extension used when the file is uploaded.
  static const String extension = 'pdf';

  final Uint8List bytes;

  /// File name shown to the owner, e.g. `rules.pdf`.
  final String name;

  bool get isTooLarge => bytes.length > maxBytes;

  @override
  List<Object?> get props => [bytes, name];
}
