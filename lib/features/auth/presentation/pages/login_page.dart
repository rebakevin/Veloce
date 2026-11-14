import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/app_messenger.dart';
import 'package:veloce/core/widgets/field_hints.dart';
import 'package:veloce/core/widgets/primary_button.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/login_bloc.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/brand_mark.dart';
import '../widgets/form_text_field.dart';
import '../widgets/google_button.dart';
import '../widgets/or_divider.dart';
import '../widgets/password_field.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.instance<LoginBloc>(),
      child: const LoginView(),
    );
  }
}

/// The login form. Needs a [LoginBloc] and an [AuthBloc] above it.
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() => context.read<LoginBloc>().add(
    LoginSubmitted(email: _email.text, password: _password.text),
  );

  Future<void> _onState(BuildContext context, LoginState state) async {
    switch (state.status) {
      case LoginStatus.failure:
        GetIt.instance<AppMessenger>().error(
          state.message ?? 'Could not sign in. Please try again.',
        );
      case LoginStatus.needsRegistration:
        await _openGoogleRegistration(context);
      case LoginStatus.idle ||
          LoginStatus.invalid ||
          LoginStatus.submitting ||
          LoginStatus.success:
        // Success: AuthBloc follows the session and the router moves on.
        break;
    }
  }

  /// The register flow reads the Google user from [AuthBloc], so wait until
  /// it has loaded (and found no profile) before opening it.
  Future<void> _openGoogleRegistration(BuildContext context) async {
    final auth = context.read<AuthBloc>();
    if (auth.state is! AuthNeedsProfile) {
      await auth.stream.firstWhere((state) => state is AuthNeedsProfile);
    }
    if (!context.mounted) return;
    context.go(RouteNames.registerRole);
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: BlocConsumer<LoginBloc, LoginState>(
        listener: _onState,
        builder: (context, state) {
          final emailBusy =
              state.isSubmitting && state.method == LoginMethod.email;
          final googleBusy =
              state.isSubmitting && state.method == LoginMethod.google;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: BrandMark()),
              const SizedBox(height: AppSpacing.xl),
              const Text('Welcome back', style: AppTextStyles.display),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Log in to rent or manage your cars.',
                style: AppTextStyles.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.xl),
              FormTextField(
                label: 'Email',
                hint: FieldHints.email,
                controller: _email,
                errorText: state.emailError,
                enabled: !state.isSubmitting,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
              ),
              const SizedBox(height: AppSpacing.lg),
              PasswordField(
                hint: FieldHints.password,
                controller: _password,
                errorText: state.passwordError,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push(RouteNames.forgotPassword),
                  child: const Text('Forgot password?'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              PrimaryButton(
                label: 'Log in',
                isLoading: emailBusy,
                onPressed: state.isSubmitting ? null : _submit,
              ),
              const SizedBox(height: AppSpacing.lg),
              const OrDivider(),
              const SizedBox(height: AppSpacing.lg),
              GoogleButton(
                isLoading: googleBusy,
                onPressed: state.isSubmitting
                    ? null
                    : () => context.read<LoginBloc>().add(
                        const LoginGoogleRequested(),
                      ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('New to Veloce?'),
                  TextButton(
                    onPressed: () => context.push(RouteNames.registerRole),
                    child: const Text('Create an account'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
