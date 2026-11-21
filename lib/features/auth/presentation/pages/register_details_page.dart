import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:veloce/core/constants/app_constants.dart';
import 'package:veloce/core/domain/entities/document_photo.dart';
import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/date_picker_field.dart';
import 'package:veloce/core/widgets/document_photo_field.dart';
import 'package:veloce/core/widgets/field_hints.dart';
import 'package:veloce/core/widgets/photo_picker.dart';
import 'package:veloce/core/widgets/primary_button.dart';

import '../bloc/register_bloc.dart';
import '../bloc/register_draft.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_top_bar.dart';
import '../widgets/fields_card.dart';
import '../widgets/form_text_field.dart';
import '../widgets/password_field.dart';
import '../widgets/register_submitting_view.dart';
import '../widgets/step_header.dart';

/// Step 2: personal details and the identity document. Needs the flow's
/// [RegisterBloc] above it.
class RegisterDetailsPage extends StatelessWidget {
  const RegisterDetailsPage({
    super.key,
    this.pickPhoto = const ImagePickerPhotoPicker(
      sources: [PhotoSource.camera, PhotoSource.gallery],
    ),
  });

  /// Opens the camera or gallery. Replaced in tests.
  final PhotoPicker pickPhoto;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<RegisterBloc>();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) bloc.add(const RegisterBackPressed());
      },
      child: AuthScaffold(
        child: BlocBuilder<RegisterBloc, RegisterState>(
          buildWhen: (previous, current) =>
              (previous.step == RegisterStep.submitting) !=
                  (current.step == RegisterStep.submitting) ||
              previous.status != current.status ||
              previous.message != current.message,
          builder: (context, state) {
            if (state.step == RegisterStep.submitting) {
              final draft = state.draft;
              return RegisterSubmittingView(
                isBusy: state.isBusy,
                message: state.message,
                isOwner: draft.role == UserRole.owner,
                name: draft.name,
                dateOfBirth: draft.dateOfBirth,
                documentNumber: draft.documentNumber,
                hasPhoto: draft.photoBytes != null,
                onRetry: () => bloc.add(const RegisterSubmitRetried()),
                onBack: () => bloc.add(const RegisterBackPressed()),
              );
            }
            return RegisterDetailsForm(pickPhoto: pickPhoto);
          },
        ),
      ),
    );
  }
}

/// The fields of the details step. Every edit goes to the bloc as it happens,
/// so the draft survives going back to the role step.
class RegisterDetailsForm extends StatefulWidget {
  const RegisterDetailsForm({required this.pickPhoto, super.key});

  final PhotoPicker pickPhoto;

  @override
  State<RegisterDetailsForm> createState() => _RegisterDetailsFormState();
}

class _RegisterDetailsFormState extends State<RegisterDetailsForm> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _password;
  late final TextEditingController _document;

  @override
  void initState() {
    super.initState();
    final draft = context.read<RegisterBloc>().state.draft;
    _name = TextEditingController(text: draft.name);
    _phone = TextEditingController(text: draft.phone);
    _email = TextEditingController(text: draft.email);
    _password = TextEditingController(text: draft.password);
    _document = TextEditingController(text: draft.documentNumber);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _document.dispose();
    super.dispose();
  }

  DocumentPhoto? _draftPhoto(RegisterDraft draft) {
    final bytes = draft.photoBytes;
    if (bytes == null || bytes.isEmpty) return null;
    return DocumentPhoto(bytes: bytes, extension: draft.photoExtension);
  }

  void _edit(RegisterDraftEdited event) =>
      context.read<RegisterBloc>().add(event);

  void _submit() =>
      context.read<RegisterBloc>().add(const RegisterDetailsSubmitted());

  @override
  Widget build(BuildContext context) {
    final now = GetIt.instance<Clock>().now();
    return BlocBuilder<RegisterBloc, RegisterState>(
      builder: (context, state) {
        final draft = state.draft;
        final errors = state.fieldErrors;
        final isOwner = draft.role == UserRole.owner;
        final isGoogle = state.isGoogle;
        final message = state.message;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthTopBar(
              onBack: () =>
                  context.read<RegisterBloc>().add(const RegisterBackPressed()),
              step: 2,
              total: isGoogle ? 2 : 3,
            ),
            const SizedBox(height: AppSpacing.lg + 2),
            StepHeader(
              title: isOwner ? 'Owner details' : 'Renter details',
              subtitle: 'We check these before you can rent or list a car.',
            ),
            const SizedBox(height: AppSpacing.lg),
            FieldsCard(
              children: [
                FormTextField(
                  label: 'Full name',
                  hint: FieldHints.fullName,
                  controller: _name,
                  errorText: errors[RegisterField.name],
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  onChanged: (value) => _edit(RegisterDraftEdited(name: value)),
                ),
                FormTextField(
                  label: 'Phone number',
                  hint: FieldHints.phone,
                  controller: _phone,
                  errorText: errors[RegisterField.phone],
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  onChanged: (value) =>
                      _edit(RegisterDraftEdited(phone: value)),
                ),
                if (!isGoogle)
                  FormTextField(
                    label: 'Email',
                    hint: FieldHints.email,
                    controller: _email,
                    errorText: errors[RegisterField.email],
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    onChanged: (value) =>
                        _edit(RegisterDraftEdited(email: value)),
                  ),
                DatePickerField(
                  label: 'Date of birth',
                  value: draft.dateOfBirth,
                  errorText: errors[RegisterField.dateOfBirth],
                  firstDate: DateTime(now.year - 100),
                  lastDate: now,
                  initialDate: DateTime(
                    now.year - AppConstants.minAdultAge,
                    now.month,
                    now.day,
                  ),
                  onChanged: (value) =>
                      _edit(RegisterDraftEdited(dateOfBirth: value)),
                ),
                if (!isOwner)
                  DatePickerField(
                    label: 'Licence expiry date',
                    value: draft.licenceExpiry,
                    errorText: errors[RegisterField.licenceExpiry],
                    firstDate: now,
                    lastDate: DateTime(now.year + 20),
                    onChanged: (value) =>
                        _edit(RegisterDraftEdited(licenceExpiry: value)),
                  ),
                FormTextField(
                  label: isOwner
                      ? 'National ID number'
                      : 'Driving licence number',
                  hint: isOwner
                      ? FieldHints.nationalId
                      : FieldHints.licenceNumber,
                  controller: _document,
                  errorText: errors[RegisterField.documentNumber],
                  keyboardType: isOwner ? TextInputType.number : null,
                  textInputAction: TextInputAction.done,
                  onChanged: (value) =>
                      _edit(RegisterDraftEdited(documentNumber: value)),
                ),
                DocumentPhotoField(
                  label: isOwner
                      ? 'Photo of your National ID'
                      : 'Photo of your driving licence',
                  initialPhoto: _draftPhoto(draft),
                  errorText: errors[RegisterField.photo],
                  removable: false,
                  picker: widget.pickPhoto,
                  onChanged: (photo) => _edit(
                    RegisterDraftEdited(
                      photoBytes: photo?.bytes,
                      photoExtension: photo?.extension,
                    ),
                  ),
                ),
                if (!isGoogle)
                  PasswordField(
                    hint: FieldHints.newPassword,
                    controller: _password,
                    errorText: errors[RegisterField.password],
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    onChanged: (value) =>
                        _edit(RegisterDraftEdited(password: value)),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: isGoogle ? 'Create account' : 'Continue',
              isLoading: state.isBusy,
              onPressed: _submit,
            ),
            if (message != null && !state.isBusy) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  color: context.colors.danger,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
