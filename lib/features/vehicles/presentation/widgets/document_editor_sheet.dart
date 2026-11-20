import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:veloce/core/domain/entities/document_photo.dart';
import 'package:veloce/core/domain/entities/vehicle.dart';
import 'package:veloce/core/domain/entities/vehicle_document.dart';
import 'package:veloce/core/domain/enums/document_kind.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/app_text_field.dart';
import 'package:veloce/core/widgets/date_picker_form_field.dart';
import 'package:veloce/core/widgets/document_photo_field.dart';
import 'package:veloce/core/widgets/photo_picker.dart';
import 'package:veloce/core/widgets/primary_button.dart';

import '../../domain/entities/document_input.dart';
import '../../domain/rules/document_rules.dart';
import '../bloc/documents_bloc.dart';

/// Form to add or replace one paper. It closes itself when the save succeeds.
class DocumentEditorSheet extends StatefulWidget {
  const DocumentEditorSheet({
    required this.kind,
    required this.vehicle,
    required this.existing,
    required this.picker,
    super.key,
  });

  final DocumentKind kind;
  final Vehicle vehicle;
  final VehicleDocument? existing;
  final PhotoPicker picker;

  @override
  State<DocumentEditorSheet> createState() => _DocumentEditorSheetState();
}

class _DocumentEditorSheetState extends State<DocumentEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _number = TextEditingController(text: widget.existing?.number);
  late final _plate = TextEditingController(text: widget.vehicle.plate);
  final _expiry = ValueNotifier<DateTime?>(null);
  DocumentPhoto? _photo;

  @override
  void dispose() {
    _number.dispose();
    _plate.dispose();
    _expiry.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    context.read<DocumentsBloc>().add(
      DocumentSubmitted(
        DocumentInput(
          kind: widget.kind,
          number: _number.text,
          plate: _plate.text,
          expiry: _expiry.value,
          photo: _photo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final label = widget.kind.label;
    return BlocConsumer<DocumentsBloc, DocumentsState>(
      listenWhen: (previous, current) =>
          current is DocumentsLoaded &&
          current.notice != null &&
          !current.notice!.isError &&
          (previous is! DocumentsLoaded || previous.notice != current.notice),
      listener: (context, state) => Navigator.of(context).pop(),
      builder: (context, state) {
        final loaded = state is DocumentsLoaded ? state : null;
        final error = loaded?.notice?.isError ?? false
            ? loaded!.notice!.message
            : null;
        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              AppSpacing.lg,
              AppSpacing.gutter,
              AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.existing == null ? 'Add $label' : 'Replace $label',
                    style: AppTextStyles.cardTitle,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  DocumentPhotoField(
                    label: 'Photo of the ${label.toLowerCase()}',
                    picker: widget.picker,
                    existingUrl: widget.existing?.photoUrl,
                    validator: (photo) =>
                        photo == null && widget.existing == null
                        ? 'Add a photo of the document.'
                        : null,
                    onChanged: (photo) => _photo = photo,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Document number',
                    hint: 'As written on the document',
                    controller: _number,
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? 'Enter the document number.'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Plate on the document',
                    hint: 'RAB 123 A',
                    controller: _plate,
                    validator: (value) =>
                        DocumentRules.plateMatches(value, widget.vehicle.plate),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DatePickerFormField(
                    label: 'Expiry date',
                    value: _expiry,
                    firstDate: now,
                    lastDate: now.add(const Duration(days: 365 * 15)),
                    validator: (date) => DocumentRules.expiry(date, now: now),
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: Text(
                        error,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: context.colors.danger,
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryButton(
                    label: 'Verify and save',
                    isLoading: loaded?.busy == DocumentsBusy.saving,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
