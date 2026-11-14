import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:veloce/core/domain/entities/document_photo.dart';
import 'package:veloce/core/layout/responsive.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/validation/validators.dart';
import 'package:veloce/core/widgets/app_text_field.dart';
import 'package:veloce/core/widgets/document_photo_field.dart';
import 'package:veloce/core/widgets/field_hints.dart';
import 'package:veloce/core/widgets/page_app_bar.dart';
import 'package:veloce/core/widgets/photo_picker.dart';
import 'package:veloce/core/widgets/primary_button.dart';

import '../../domain/entities/identity_submission.dart';
import '../bloc/profile_bloc.dart';
import '../widgets/action_message_banner.dart';
import '../widgets/profile_action_listener.dart';
import '../widgets/profile_loaded_builder.dart';

/// `/profile/identity`: view and replace the owner's National ID. The check
/// is simulated; a rejected one shows the reason and a Retry button.
class IdentityPage extends StatelessWidget {
  const IdentityPage({
    super.key,
    this.photoPicker = const ImagePickerPhotoPicker(),
  });

  final PhotoPicker photoPicker;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PageAppBar(title: 'National ID'),
      body: ProfileActionListener(
        kind: ProfileActionKind.identity,
        successMessage: 'National ID verified and saved',
        child: ProfileLoadedBuilder(
          builder: (context, state) =>
              _IdentityForm(state: state, picker: photoPicker),
        ),
      ),
    );
  }
}

class _IdentityForm extends StatefulWidget {
  const _IdentityForm({required this.state, required this.picker});

  final ProfileLoaded state;
  final PhotoPicker picker;

  @override
  State<_IdentityForm> createState() => _IdentityFormState();
}

class _IdentityFormState extends State<_IdentityForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _number;
  final ValueNotifier<DocumentPhoto?> _photo = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
    _number = TextEditingController(
      text: widget.state.identity?.nationalIdNumber,
    );
    context.read<ProfileBloc>().add(const ProfileActionAcknowledged());
  }

  @override
  void dispose() {
    _number.dispose();
    _photo.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<ProfileBloc>().add(
      ProfileIdentitySubmitted(
        IdentitySubmission(
          nationalIdNumber: _number.text.trim(),
          photo: _photo.value,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final identity = widget.state.identity;
    final action = widget.state.action;
    final isIdentity = action.kind == ProfileActionKind.identity;
    final submitting = isIdentity && action.isSubmitting;
    final rejected =
        isIdentity && action.status == ProfileActionStatus.verificationFailed;
    return Form(
      key: _formKey,
      child: ListView(
        padding: Responsive.pagePadding(context)
            .copyWith(top: AppSpacing.lg, bottom: AppSpacing.xl),
        children: [
          Text(
            identity == null
                ? 'Add your National ID so renters can trust you.'
                : 'Your National ID is saved. Replace it below if it changed.',
            style: AppTextStyles.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'National ID number',
            hint: FieldHints.nationalId,
            controller: _number,
            keyboardType: TextInputType.number,
            validator: Validators.nationalId,
          ),
          const SizedBox(height: AppSpacing.lg),
          DocumentPhotoField(
            label: 'National ID photo',
            initialPhoto: _photo.value,
            onChanged: (photo) => _photo.value = photo,
            picker: widget.picker,
            existingUrl: identity?.photoUrl,
            validator: (photo) => photo == null && identity == null
                ? 'Add a photo of your National ID.'
                : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (submitting)
            const Text('Verifying your National ID...')
          else
            ActionMessageBanner(
              action: action,
              kind: ProfileActionKind.identity,
            ),
          const SizedBox(height: AppSpacing.lg),
          if (rejected) ...[
            OutlinedButton(
              onPressed: () => context.read<ProfileBloc>().add(
                const ProfileIdentityRetried(),
              ),
              child: const Text('Retry verification'),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          PrimaryButton(
            label: identity == null ? 'Verify and save' : 'Verify and replace',
            isLoading: submitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
