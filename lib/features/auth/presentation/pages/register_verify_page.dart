import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/app_messenger.dart';
import 'package:veloce/core/widgets/field_hints.dart';
import 'package:veloce/core/widgets/primary_button.dart';

import '../bloc/register_bloc.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/form_text_field.dart';
import '../widgets/register_submitting_view.dart';
import '../widgets/step_header.dart';

/// Step 3: the simulated phone code. The generated code is shown in a
/// SnackBar every time a new one is sent. Needs the flow's [RegisterBloc].
class RegisterVerifyPage extends StatelessWidget {
  const RegisterVerifyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<RegisterBloc>();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) bloc.add(const RegisterBackPressed());
      },
      child: BlocListener<RegisterBloc, RegisterState>(
        listenWhen: (previous, current) =>
            current.challenge != null &&
            previous.challenge?.code != current.challenge?.code,
        listener: (context, state) => GetIt.instance<AppMessenger>().success(
          'Demo code for ${state.challenge!.phone}: ${state.challenge!.code}',
        ),
        child: AuthScaffold(
          title: 'Verify your phone',
          onBack: () => bloc.add(const RegisterBackPressed()),
          child: BlocBuilder<RegisterBloc, RegisterState>(
            buildWhen: (previous, current) =>
                previous.step != current.step ||
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
              return OtpForm(
                phone: state.challenge?.phone ?? state.draft.phone,
                isBusy: state.isBusy,
                errorText: state.status == RegisterStatus.failure
                    ? state.message
                    : null,
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The 6-digit code field with Verify and Resend.
class OtpForm extends StatefulWidget {
  const OtpForm({
    required this.phone,
    required this.isBusy,
    super.key,
    this.errorText,
  });

  final String phone;
  final bool isBusy;
  final String? errorText;

  @override
  State<OtpForm> createState() => _OtpFormState();
}

class _OtpFormState extends State<OtpForm> {
  final TextEditingController _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _verify() =>
      context.read<RegisterBloc>().add(RegisterOtpSubmitted(_code.text));

  @override
  Widget build(BuildContext context) {
    final failed = widget.errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StepHeader(
          step: 3,
          total: 4,
          title: 'Enter the 6-digit code',
          subtitle: 'We sent a code to ${widget.phone}.',
        ),
        FormTextField(
          label: 'Verification code',
          hint: FieldHints.verificationCode,
          controller: _code,
          errorText: widget.errorText,
          enabled: !widget.isBusy,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.oneTimeCode],
          maxLength: 6,
          onChanged: (_) =>
              context.read<RegisterBloc>().add(const RegisterOtpEdited()),
          onSubmitted: (_) => _verify(),
        ),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: failed ? 'Try again' : 'Verify',
          isLoading: widget.isBusy,
          onPressed: _verify,
        ),
        const SizedBox(height: AppSpacing.md),
        TextButton(
          onPressed: widget.isBusy
              ? null
              : () =>
                    context.read<RegisterBloc>().add(const RegisterOtpResent()),
          child: const Text('Resend code', style: AppTextStyles.button),
        ),
      ],
    );
  }
}
