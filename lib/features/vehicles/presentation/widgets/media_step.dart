import 'package:flutter/material.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/image_picker_tile.dart';
import 'package:veloce/core/widgets/photo_picker.dart';
import 'package:veloce/core/widgets/status_chip.dart';

import '../../domain/entities/wizard_draft.dart';
import '../../domain/rules/wizard_step_rules.dart';

class MediaStep extends StatelessWidget {
  const MediaStep({
    required this.draft,
    required this.errors,
    required this.onChanged,
    super.key,
    this.picker = const ImagePickerPhotoPicker(),
  });

  final WizardDraft draft;
  final Map<WizardField, String> errors;
  final ValueChanged<WizardDraft> onChanged;
  final PhotoPicker picker;

  Future<void> _add(BuildContext context) async {
    final photo = await picker.pick(context);
    if (photo == null) return;
    onChanged(draft.copyWith(photos: [...draft.photos, photo]));
  }

  void _remove(int index) {
    final kept = draft.keptPhotos.length;
    final keptPhotos = [...draft.keptPhotos];
    final photos = [...draft.photos];
    if (index < kept) {
      keptPhotos.removeAt(index);
    } else {
      photos.removeAt(index - kept);
    }
    var primary = draft.primaryIndex;
    if (index == primary) {
      primary = 0;
    } else if (index < primary) {
      primary -= 1;
    }
    onChanged(
      draft.copyWith(
        keptPhotos: keptPhotos,
        photos: photos,
        primaryIndex: primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final error = errors[WizardField.photos];
    final count = draft.photoCount;
    final kept = draft.keptPhotos.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Add ${WizardStepRules.minPhotos} to ${WizardStepRules.maxPhotos} '
          'photos. Tap a photo to make it the main one.',
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.3,
          children: [
            for (var i = 0; i < count; i++)
              Stack(
                children: [
                  Positioned.fill(
                    child: ImagePickerTile(
                      label: 'Photo ${i + 1}',
                      imageUrl: i < kept ? draft.keptPhotos[i].url : null,
                      imageBytes: i < kept
                          ? null
                          : draft.photos[i - kept].bytes,
                      onTap: () => onChanged(draft.copyWith(primaryIndex: i)),
                      onRemove: () => _remove(i),
                    ),
                  ),
                  if (i == draft.primaryIndex)
                    const Positioned(
                      left: AppSpacing.sm,
                      bottom: AppSpacing.sm,
                      child: StatusChip(
                        label: 'Main photo',
                        tone: StatusTone.active,
                      ),
                    ),
                ],
              ),
            if (count < WizardStepRules.maxPhotos)
              ImagePickerTile(label: 'Add photo', onTap: () => _add(context)),
          ],
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              error,
              style: AppTextStyles.bodySmall.copyWith(
                color: context.colors.danger,
              ),
            ),
          ),
      ],
    );
  }
}
