import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Tap target that shows a picked image (bytes or URL) or an add prompt.
/// Picking itself happens in the caller via `image_picker` with
/// `imageQuality: 80` and `maxWidth: 1600`.
class ImagePickerTile extends StatelessWidget {
  const ImagePickerTile({
    required this.label,
    required this.onTap,
    super.key,
    this.imageBytes,
    this.imageUrl,
    this.onRemove,
  });

  final String label;
  final VoidCallback onTap;
  final Uint8List? imageBytes;
  final String? imageUrl;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bytes = imageBytes;
    final url = imageUrl;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Ink(
          height: 120,
          decoration: BoxDecoration(
            color: colors.paper,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: colors.line, width: 1.5),
            image: bytes != null
                ? DecorationImage(image: MemoryImage(bytes), fit: BoxFit.cover)
                : url != null
                ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
                : null,
          ),
          child: bytes == null && url == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_a_photo_outlined, color: colors.brand),
                      const SizedBox(height: AppSpacing.xs),
                      Text(label),
                    ],
                  ),
                )
              : Align(
                  alignment: Alignment.topRight,
                  child: onRemove == null
                      ? null
                      : IconButton.filledTonal(
                          tooltip: 'Remove photo',
                          onPressed: onRemove,
                          icon: const Icon(Icons.close),
                        ),
                ),
        ),
      ),
    );
  }
}
