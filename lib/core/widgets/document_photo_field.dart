import 'package:flutter/material.dart';

import '../domain/entities/document_photo.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'image_picker_tile.dart';
import 'photo_picker.dart';

/// A form field that picks a photo. [onChanged] receives every pick and
/// removal; [existingUrl] is shown until a new photo is picked. The error
/// shown is the [validator]'s, or [errorText] when the owner of the state
/// supplies one.
class DocumentPhotoField extends StatelessWidget {
  const DocumentPhotoField({
    required this.label,
    required this.picker,
    required this.onChanged,
    super.key,
    this.initialPhoto,
    this.existingUrl,
    this.validator,
    this.errorText,
    this.removable = true,
  });

  final String label;
  final PhotoPicker picker;
  final ValueChanged<DocumentPhoto?> onChanged;
  final DocumentPhoto? initialPhoto;
  final String? existingUrl;
  final String? Function(DocumentPhoto? value)? validator;
  final String? errorText;

  /// Whether a picked photo can be cleared again.
  final bool removable;

  @override
  Widget build(BuildContext context) {
    return FormField<DocumentPhoto>(
      initialValue: initialPhoto,
      validator: validator,
      builder: (field) {
        final value = field.value;
        final error = field.errorText ?? errorText;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ImagePickerTile(
              label: label,
              imageBytes: value?.bytes,
              imageUrl: value == null ? existingUrl : null,
              onRemove: value == null || !removable
                  ? null
                  : () {
                      onChanged(null);
                      field.didChange(null);
                    },
              onTap: () async {
                final picked = await picker.pick(context);
                if (picked == null) return;
                onChanged(picked);
                field.didChange(picked);
              },
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  error,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.colors.danger,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
