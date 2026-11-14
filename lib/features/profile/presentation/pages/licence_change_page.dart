import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:veloce/core/domain/entities/document_photo.dart';
import 'package:veloce/core/layout/responsive.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/validation/validators.dart';
import 'package:veloce/core/widgets/app_text_field.dart';
import 'package:veloce/core/widgets/date_picker_form_field.dart';
import 'package:veloce/core/widgets/document_photo_field.dart';
import 'package:veloce/core/widgets/page_app_bar.dart';
import 'package:veloce/core/widgets/photo_picker.dart';
import 'package:veloce/core/widgets/primary_button.dart';

import '../../domain/entities/licence_submission.dart';
import '../bloc/profile_bloc.dart';
import '../widgets/profile_loaded_builder.dart';

/// `/profile/licence/change` (step 2 of 3): number, expiry and photo. Sending
/// the form starts the simulated check and opens the verify screen.
class LicenceChangePage extends StatelessWidget {
  const LicenceChangePage({
    super.key,
    this.photoPicker = const ImagePickerPhotoPicker(),
  });

  final PhotoPicker photoPicker;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PageAppBar(title: 'Change licence'),
      body: ProfileLoadedBuilder(
        builder: (context, state) =>
            _LicenceForm(state: state, picker: photoPicker),
      ),
    );
  }
}

class _LicenceForm extends StatefulWidget {
  const _LicenceForm({required this.state, required this.picker});

  final ProfileLoaded state;
  final PhotoPicker picker;

  @override
  State<_LicenceForm> createState() => _LicenceFormState();
}

class _LicenceFormState extends State<_LicenceForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _number;
  late final ValueNotifier<DateTime?> _expiry;
  final ValueNotifier<DocumentPhoto?> _photo = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
    final licence = widget.state.licence;
    _number = TextEditingController(text: licence?.number);
    _expiry = ValueNotifier(licence?.expiry);
    context.read<ProfileBloc>().add(const ProfileActionAcknowledged());
  }

  @override
  void dispose() {
    _number.dispose();
    _expiry.dispose();
    _photo.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<ProfileBloc>().add(
      ProfileLicenceSubmitted(
        LicenceSubmission(
          number: _number.text.trim(),
          expiry: _expiry.value!,
          photo: _photo.value,
        ),
      ),
    );
    context.push(RouteNames.profileLicenceVerify);
  }

  @override
  Widget build(BuildContext context) {
    final licence = widget.state.licence;
    final now = DateTime.now();
    return Form(
      key: _formKey,
      child: ListView(
        padding: Responsive.pagePadding(context)
            .copyWith(top: AppSpacing.lg, bottom: AppSpacing.xl),
        children: [
          AppTextField(
            label: 'Licence number',
            controller: _number,
            textInputAction: TextInputAction.next,
            validator: Validators.licenceNumber,
          ),
          const SizedBox(height: AppSpacing.lg),
          DatePickerFormField(
            label: 'Expiry date',
            value: _expiry,
            firstDate: now,
            lastDate: DateTime(now.year + 20),
            validator: (value) => Validators.licenceExpiry(value, now: now),
          ),
          const SizedBox(height: AppSpacing.lg),
          DocumentPhotoField(
            label: 'Licence photo',
            initialPhoto: _photo.value,
            onChanged: (photo) => _photo.value = photo,
            picker: widget.picker,
            existingUrl: licence?.photoUrl,
            validator: (photo) => photo == null && licence == null
                ? 'Add a photo of your licence.'
                : null,
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(label: 'Verify licence', onPressed: _submit),
        ],
      ),
    );
  }
}
