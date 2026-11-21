import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:veloce/core/domain/enums/document_kind.dart';
import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/date_picker_field.dart';
import 'package:veloce/core/widgets/document_photo_field.dart';
import 'package:veloce/core/widgets/photo_picker.dart';
import 'package:veloce/core/widgets/status_chip.dart';

import '../../domain/entities/wizard_draft.dart';
import '../../domain/rules/document_rules.dart';
import '../../domain/rules/wizard_step_rules.dart';
import 'draft_text_field.dart';

class DocumentsStep extends StatelessWidget {
  const DocumentsStep({
    required this.draft,
    required this.errors,
    required this.verifying,
    required this.onChanged,
    required this.onVerify,
    super.key,
    this.picker = const ImagePickerPhotoPicker(),
  });

  final WizardDraft draft;
  final Map<WizardField, String> errors;
  final DocumentKind? verifying;
  final ValueChanged<WizardDraft> onChanged;
  final ValueChanged<DocumentKind> onVerify;
  final PhotoPicker picker;

  void _update(DocumentKind kind, DraftDocument Function(DraftDocument) edit) {
    final current = draft.documents[kind] ?? const DraftDocument();
    onChanged(
      draft.copyWith(documents: {...draft.documents, kind: edit(current)}),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final kind in DocumentKind.values)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: _DocumentCard(
              kind: kind,
              document: draft.documents[kind] ?? const DraftDocument(),
              optional: !DocumentRules.requiredKinds.contains(kind),
              error: errors[WizardStepRules.documentFields[kind]],
              isVerifying: verifying == kind,
              busy: verifying != null,
              picker: picker,
              onEdit: (edit) => _update(kind, edit),
              onVerify: () => onVerify(kind),
            ),
          ),
      ],
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.kind,
    required this.document,
    required this.optional,
    required this.error,
    required this.isVerifying,
    required this.busy,
    required this.picker,
    required this.onEdit,
    required this.onVerify,
  });

  final DocumentKind kind;
  final DraftDocument document;
  final bool optional;
  final String? error;
  final bool isVerifying;
  final bool busy;
  final PhotoPicker picker;
  final void Function(DraftDocument Function(DraftDocument)) onEdit;
  final VoidCallback onVerify;

  bool get _canVerify =>
      document.photo != null &&
      document.number.trim().isNotEmpty &&
      document.expiry != null &&
      !document.verified &&
      !busy;

  @override
  Widget build(BuildContext context) {
    final now = GetIt.I<Clock>().now();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(kind.label, style: AppTextStyles.cardTitle),
                ),
                if (document.verified)
                  const StatusChip(label: 'Verified', tone: StatusTone.active),
              ],
            ),
            if (optional)
              const Padding(
                padding: EdgeInsets.only(top: AppSpacing.xs),
                child: Text('Optional. You can add it later.'),
              ),
            const SizedBox(height: AppSpacing.md),
            DocumentPhotoField(
              label: 'Photo of the ${kind.label.toLowerCase()}',
              picker: picker,
              initialPhoto: document.photo,
              onChanged: (photo) => onEdit(
                (current) => photo == null
                    ? current.copyWith(clearPhoto: true, verified: false)
                    : current.copyWith(photo: photo, verified: false),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            DraftTextField(
              label: 'Document number',
              hint: 'As written on the document',
              initialValue: document.number,
              onChanged: (value) => onEdit(
                (current) => current.copyWith(number: value, verified: false),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            DraftTextField(
              label: 'Plate on the document',
              hint: 'RAB 123 A',
              initialValue: document.plate,
              onChanged: (value) => onEdit(
                (current) => current.copyWith(plate: value, verified: false),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            DatePickerField(
              label: 'Expiry date',
              value: document.expiry,
              firstDate: now,
              lastDate: now.add(const Duration(days: 365 * 15)),
              onChanged: (date) => onEdit(
                (current) => current.copyWith(expiry: date, verified: false),
              ),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  error!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.colors.danger,
                  ),
                ),
              ),
            if (!document.verified)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: FilledButton.tonal(
                  onPressed: _canVerify ? onVerify : null,
                  child: isVerifying
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Verify document'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
