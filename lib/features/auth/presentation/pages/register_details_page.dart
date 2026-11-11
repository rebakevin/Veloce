import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:veloce/core/constants/app_constants.dart';
import 'package:veloce/core/domain/entities/document_photo.dart';
import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/widgets/date_picker_field.dart';
import 'package:veloce/core/widgets/document_photo_field.dart';
import 'package:veloce/core/widgets/photo_picker.dart';
import 'package:veloce/core/widgets/primary_button.dart';

import '../bloc/register_bloc.dart';
import '../bloc/register_draft.dart';
import '../widgets/auth_scaffold.dart';
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
        title: 'Your details',
        onBack: () => bloc.add(const RegisterBackPressed()),
        child: BlocBuilder<RegisterBloc, RegisterState>(
          buildWhen: (previous, current) =>
              (previous.step == RegisterStep.submitting) !=
                  (current.step == RegisterStep.submitting) ||
              previous.status != current.status ||
              previous.message != current.message,
          builder: (context, state) {
            if (state.step == RegisterStep.submitting) {
              return RegisterSubmittingView(
                isBusy: state.isBusy,
                message: state.message,
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
/// so the draft survives going back from the OTP step.
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
            StepHeader(
              step: 2,
              total: isGoogle ? 2 : 4,
              title: isOwner ? 'Owner details' : 'Renter details',
              subtitle: 'We check these before you can rent or list a car.',
            ),
            FormTextField(
              label: 'Full name',
              controller: _name,
              errorText: errors[RegisterField.name],
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              onChanged: (value) => _edit(RegisterDraftEdited(name: value)),
            ),
            const SizedBox(height: AppSpacing.lg),
            FormTextField(
              label: 'Phone number',
              hint: '0788123456',
              controller: _phone,
              errorText: errors[RegisterField.phone],
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.telephoneNumber],
              onChanged: (value) => _edit(RegisterDraftEdited(phone: value)),
            ),
            if (!isGoogle) ...[
              const SizedBox(height: AppSpacing.lg),
              FormTextField(
                label: 'Email',
                controller: _email,
                errorText: errors[RegisterField.email],
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                onChanged: (value) => _edit(RegisterDraftEdited(email: value)),
              ),
              const SizedBox(height: AppSpacing.lg),
              PasswordField(
                controller: _password,
                errorText: errors[RegisterField.password],
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                onChanged: (value) =>
                    _edit(RegisterDraftEdited(password: value)),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
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
            const SizedBox(height: AppSpacing.lg),
            FormTextField(
              label: isOwner ? 'National ID number' : 'Driving licence number',
              controller: _document,
              errorText: errors[RegisterField.documentNumber],
              keyboardType: isOwner ? TextInputType.number : null,
              textInputAction: TextInputAction.done,
              onChanged: (value) =>
                  _edit(RegisterDraftEdited(documentNumber: value)),
            ),
            if (!isOwner) ...[
              const SizedBox(height: AppSpacing.lg),
              DatePickerField(
                label: 'Licence expiry date',
                value: draft.licenceExpiry,
                errorText: errors[RegisterField.licenceExpiry],
                firstDate: now,
                lastDate: DateTime(now.year + 20),
                onChanged: (value) =>
                    _edit(RegisterDraftEdited(licenceExpiry: value)),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
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
            const SizedBox(height: AppSpacing.xl),
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
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        );
      },
    );
  }
}
