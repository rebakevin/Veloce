import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/app_messenger.dart';
import 'package:veloce/core/widgets/field_hints.dart';
import 'package:veloce/core/widgets/primary_button.dart';

import '../bloc/forgot_password_cubit.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_top_bar.dart';
import '../widgets/fields_card.dart';
import '../widgets/form_text_field.dart';
import '../widgets/step_header.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.instance<ForgotPasswordCubit>(),
      child: const ForgotPasswordView(),
    );
  }
}

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final TextEditingController _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _submit() => context.read<ForgotPasswordCubit>().submit(_email.text);

  void _back() =>
      context.canPop() ? context.pop() : context.go(RouteNames.login);

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: BlocConsumer<ForgotPasswordCubit, ForgotPasswordState>(
        listenWhen: (previous, current) =>
            current.status == ForgotPasswordStatus.failure,
        listener: (context, state) => GetIt.instance<AppMessenger>().error(
          state.message ?? 'Could not send the email. Try again.',
        ),
        builder: (context, state) {
          if (state.status == ForgotPasswordStatus.sent) {
            return _SentNotice(
              email: _email.text.trim(),
              onDifferentEmail: context.read<ForgotPasswordCubit>().reset,
              onBack: _back,
            );
          }
          final sending = state.status == ForgotPasswordStatus.sending;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthTopBar(onBack: _back),
              const SizedBox(height: AppSpacing.lg + 2),
              const StepHeader(
                title: 'Forgot password',
                subtitle:
                    'Enter the email you signed up with and we will send '
                    'you a link to choose a new password.',
              ),
              const SizedBox(height: AppSpacing.lg),
              FieldsCard(
                children: [
                  FormTextField(
                    label: 'Email',
                    hint: FieldHints.email,
                    controller: _email,
                    errorText: state.emailError,
                    enabled: !sending,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.email],
                    onChanged: (_) =>
                        context.read<ForgotPasswordCubit>().emailEdited(),
                    onSubmitted: (_) => _submit(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg + 2),
              PrimaryButton(
                label: 'Send reset link',
                isLoading: sending,
                onPressed: _submit,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SentNotice extends StatelessWidget {
  const _SentNotice({
    required this.email,
    required this.onDifferentEmail,
    required this.onBack,
  });

  final String email;
  final VoidCallback onDifferentEmail;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthTopBar(onBack: onBack),
        const SizedBox(height: AppSpacing.xl),
        Align(
          alignment: Alignment.centerLeft,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.brandTint,
              shape: BoxShape.circle,
            ),
            child: SizedBox.square(
              dimension: 72,
              child: Icon(
                Icons.mark_email_read_outlined,
                size: 36,
                color: colors.brandDeep,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg + 2),
        const StepHeader(title: 'Check your email'),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'If $email has an account, a reset link is on its way.',
          style: AppTextStyles.bodyLarge.copyWith(color: colors.muted),
        ),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(label: 'Back to log in', onPressed: onBack),
        TextButton(
          onPressed: onDifferentEmail,
          child: const Text('Use a different email'),
        ),
      ],
    );
  }
}
