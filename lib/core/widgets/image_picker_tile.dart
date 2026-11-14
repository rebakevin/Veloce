import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Tap target that shows a picked image (bytes or URL) or an add prompt.
/// Picking itself happens in the caller via `image_picker` with
/// `imageQuality: 80` and `maxWidth: 1600`.
class ImagePickerTile extends StatelessWidget {
  /// The tile's height when it holds a photo, and its least height otherwise
  /// (the add prompt grows past it with large text).
  static const double _height = 120;

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
          decoration: BoxDecoration(
            color: colors.paper,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: colors.line, width: 1.5),
            image: bytes == null
                ? null
                : DecorationImage(image: MemoryImage(bytes), fit: BoxFit.cover),
          ),
          child: bytes != null
              ? ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: _height),
                  child: _RemoveButton(onRemove: onRemove),
                )
              : url == null
              ? ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: _height),
                  child: _AddPrompt(label: label),
                )
              : SizedBox(
                  height: _height,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Under the photo: shown while it loads and when it
                        // cannot be loaded (offline, host gone).
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: _AddPrompt(label: label),
                        ),
                        Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                        _RemoveButton(onRemove: onRemove),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _AddPrompt extends StatelessWidget {
  const _AddPrompt({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add_a_photo_outlined, color: context.colors.brand),
          const SizedBox(height: AppSpacing.xs),
          Text(label),
        ],
      ),
    );
  }
}

class _RemoveButton extends StatelessWidget {
  const _RemoveButton({required this.onRemove});

  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: onRemove == null
          ? null
          : IconButton.filledTonal(
              tooltip: 'Remove photo',
              onPressed: onRemove,
              icon: const Icon(Icons.close),
            ),
    );
  }
}
