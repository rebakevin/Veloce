import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// A picked, already compressed image waiting to be uploaded.
class DocumentPhoto extends Equatable {
  const DocumentPhoto({required this.bytes, required this.extension});

  final Uint8List bytes;

  /// File extension without the dot, e.g. `jpg`.
  final String extension;

  bool get isEmpty => bytes.isEmpty;

  @override
  List<Object?> get props => [bytes, extension];
}
