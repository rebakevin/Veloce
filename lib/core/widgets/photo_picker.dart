import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../domain/entities/document_photo.dart';

/// Where a photo can come from.
enum PhotoSource { camera, gallery }

/// Picks one photo. A seam so screens can be tested without the platform
/// plugin.
abstract interface class PhotoPicker {
  /// The compressed photo, or `null` when the user cancelled.
  Future<DocumentPhoto?> pick(BuildContext context);
}

/// Picker through `image_picker`, compressed before upload
/// (`imageQuality: 80`, `maxWidth: 1600`). With several [sources] it asks
/// first through a bottom sheet; with one it picks straight away.
class ImagePickerPhotoPicker implements PhotoPicker {
  const ImagePickerPhotoPicker({
    this.sources = const [PhotoSource.gallery, PhotoSource.camera],
  });

  final List<PhotoSource> sources;

  @override
  Future<DocumentPhoto?> pick(BuildContext context) async {
    final PhotoSource? source;
    if (sources.length == 1) {
      source = sources.first;
    } else {
      source = await showModalBottomSheet<PhotoSource>(
        context: context,
        builder: (sheet) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final option in sources)
                ListTile(
                  leading: Icon(_icon(option)),
                  title: Text(_title(option)),
                  onTap: () => Navigator.of(sheet).pop(option),
                ),
            ],
          ),
        ),
      );
    }
    if (source == null) return null;
    final file = await ImagePicker().pickImage(
      source: source == PhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    final dot = file.name.lastIndexOf('.');
    final extension = dot == -1 ? 'jpg' : file.name.substring(dot + 1);
    return DocumentPhoto(bytes: bytes, extension: extension.toLowerCase());
  }

  static IconData _icon(PhotoSource source) => switch (source) {
    PhotoSource.camera => Icons.photo_camera_outlined,
    PhotoSource.gallery => Icons.photo_library_outlined,
  };

  static String _title(PhotoSource source) => switch (source) {
    PhotoSource.camera => 'Take a photo',
    PhotoSource.gallery => 'Choose from gallery',
  };
}
