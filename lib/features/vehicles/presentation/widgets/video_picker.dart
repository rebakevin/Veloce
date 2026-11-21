import 'package:image_picker/image_picker.dart';
import 'package:veloce/core/domain/entities/document_photo.dart';

/// Picks one short video. A seam so screens can be tested without the
/// platform plugin.
abstract interface class VideoPicker {
  /// The picked video, or `null` when the user cancelled.
  Future<DocumentPhoto?> pick();
}

/// Picker through `image_picker`, limited to 30 seconds from the gallery.
class ImagePickerVideoPicker implements VideoPicker {
  const ImagePickerVideoPicker();

  @override
  Future<DocumentPhoto?> pick() async {
    final file = await ImagePicker().pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 30),
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    final dot = file.name.lastIndexOf('.');
    final extension = dot == -1 ? 'mp4' : file.name.substring(dot + 1);
    return DocumentPhoto(bytes: bytes, extension: extension.toLowerCase());
  }
}
