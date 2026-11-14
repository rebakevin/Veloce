import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:veloce/core/domain/entities/document_photo.dart';
import 'package:veloce/core/layout/responsive.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/validation/validators.dart';
import 'package:veloce/core/widgets/app_text_field.dart';
import 'package:veloce/core/widgets/date_picker_form_field.dart';
import 'package:veloce/core/widgets/document_photo_field.dart';
import 'package:veloce/core/widgets/page_app_bar.dart';
import 'package:veloce/core/widgets/photo_picker.dart';
import 'package:veloce/core/widgets/primary_button.dart';

import '../../domain/entities/profile_update.dart';
import '../bloc/profile_bloc.dart';
import '../widgets/action_message_banner.dart';
import '../widgets/profile_action_listener.dart';
import '../widgets/profile_loaded_builder.dart';

/// `/profile/edit`: name, phone, date of birth (18+) and photo.
class EditProfilePage extends StatelessWidget {
  const EditProfilePage({
    super.key,
    this.photoPicker = const ImagePickerPhotoPicker(),
  });

  final PhotoPicker photoPicker;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PageAppBar(title: 'Edit profile'),
      body: ProfileActionListener(
        kind: ProfileActionKind.updateProfile,
        successMessage: 'Profile updated',
        child: ProfileLoadedBuilder(
          builder: (context, state) =>
              _EditProfileForm(state: state, picker: photoPicker),
        ),
      ),
    );
  }
}

class _EditProfileForm extends StatefulWidget {
  const _EditProfileForm({required this.state, required this.picker});

  final ProfileLoaded state;
  final PhotoPicker picker;

  @override
  State<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends State<_EditProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final ValueNotifier<DateTime?> _dateOfBirth;
  final ValueNotifier<DocumentPhoto?> _photo = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.state.account.name);
    _phone = TextEditingController(text: widget.state.contact.phone);
    _dateOfBirth = ValueNotifier(widget.state.contact.dateOfBirth);
    // Forget a result left over from an earlier visit.
    context.read<ProfileBloc>().add(const ProfileActionAcknowledged());
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _dateOfBirth.dispose();
    _photo.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<ProfileBloc>().add(
      ProfileUpdateSubmitted(
        ProfileUpdate(
          name: _name.text.trim(),
          phone: _phone.text.trim(),
          dateOfBirth: _dateOfBirth.value!,
          newPhoto: _photo.value,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final action = widget.state.action;
    final now = DateTime.now();
    return Form(
      key: _formKey,
      child: ListView(
        padding: Responsive.pagePadding(context)
            .copyWith(top: AppSpacing.lg, bottom: AppSpacing.xl),
        children: [
          DocumentPhotoField(
            label: 'Profile photo',
            initialPhoto: _photo.value,
            onChanged: (photo) => _photo.value = photo,
            picker: widget.picker,
            existingUrl: widget.state.account.photoUrl,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'Full name',
            controller: _name,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            validator: (value) => Validators.requiredText(value, field: 'Name'),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'Phone number',
            hint: '0788123456',
            controller: _phone,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.telephoneNumber],
            validator: Validators.phone,
          ),
          const SizedBox(height: AppSpacing.lg),
          DatePickerFormField(
            label: 'Date of birth',
            value: _dateOfBirth,
            firstDate: DateTime(now.year - 100),
            lastDate: now,
            validator: (value) => Validators.dateOfBirth(value, now: now),
          ),
          const SizedBox(height: AppSpacing.lg),
          ActionMessageBanner(
            action: action,
            kind: ProfileActionKind.updateProfile,
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'Save changes',
            isLoading: action.isSubmitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
