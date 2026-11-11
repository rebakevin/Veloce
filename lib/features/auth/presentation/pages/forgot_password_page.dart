import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/app_messenger.dart';
import 'package:veloce/core/widgets/primary_button.dart';

import '../bloc/forgot_password_cubit.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/form_text_field.dart';

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
      title: 'Forgot password',
      onBack: _back,
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
              const Text(
                'Enter the email you signed up with and we will send you a '
                'link to choose a new password.',
                style: AppTextStyles.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.xl),
              FormTextField(
                label: 'Email',
                controller: _email,
                errorText: state.emailError,
                enabled: !sending,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.email],
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.xl),
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
        const SizedBox(height: AppSpacing.xl),
        Icon(Icons.mark_email_read_outlined, size: 64, color: colors.brand),
        const SizedBox(height: AppSpacing.lg),
        const Text(
          'Check your email',
          style: AppTextStyles.title,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'If $email has an account, a reset link is on its way.',
          style: AppTextStyles.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        FilledButton(onPressed: onBack, child: const Text('Back to log in')),
        TextButton(
          onPressed: onDifferentEmail,
          child: const Text('Use a different email'),
        ),
      ],
    );
  }
}
