import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:veloce/core/domain/enums/auth_provider_kind.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/validation/validators.dart';
import 'package:veloce/core/widgets/app_text_field.dart';
import 'package:veloce/core/widgets/primary_button.dart';
import 'package:veloce/features/auth/auth.dart';

/// Signs another account in (email and password, or Google) with its own
/// [LoginBloc], then calls [onSignedIn]. [onSignedIn] gets the password for an
/// email sign-in and `null` for Google.
///
/// With [email] set the address is fixed (re-sign-in of a linked account) and
/// [kind] picks which method is offered.
class AccountSignInForm extends StatelessWidget {
  const AccountSignInForm({
    required this.onSignedIn,
    super.key,
    this.email,
    this.kind,
  });

  final String? email;
  final AuthProviderKind? kind;
  final void Function(String? password) onSignedIn;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LoginBloc>(
      create: (_) => GetIt.instance<LoginBloc>(),
      child: _SignInBody(email: email, kind: kind, onSignedIn: onSignedIn),
    );
  }
}

class _SignInBody extends StatefulWidget {
  const _SignInBody({
    required this.email,
    required this.kind,
    required this.onSignedIn,
  });

  final String? email;
  final AuthProviderKind? kind;
  final void Function(String? password) onSignedIn;

  @override
  State<_SignInBody> createState() => _SignInBodyState();
}

class _SignInBodyState extends State<_SignInBody> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email;
  final _password = TextEditingController();
  bool _usedGoogle = false;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.email);
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _signInWithEmail() {
    if (!_formKey.currentState!.validate()) return;
    _usedGoogle = false;
    context.read<LoginBloc>().add(
      LoginSubmitted(email: _email.text.trim(), password: _password.text),
    );
  }

  void _signInWithGoogle() {
    _usedGoogle = true;
    context.read<LoginBloc>().add(const LoginGoogleRequested());
  }

  @override
  Widget build(BuildContext context) {
    final showEmail = widget.kind != AuthProviderKind.google;
    final showGoogle = widget.kind != AuthProviderKind.password;
    return BlocConsumer<LoginBloc, LoginState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == LoginStatus.success,
      listener: (context, state) =>
          widget.onSignedIn(_usedGoogle ? null : _password.text),
      builder: (context, state) {
        final message = switch (state.status) {
          LoginStatus.failure => state.message,
          LoginStatus.needsRegistration =>
            'This Google account has no Veloce profile yet. Register it first.',
          _ => null,
        };
        return Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showEmail) ...[
                AppTextField(
                  label: 'Email',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: Validators.email,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'Password',
                  controller: _password,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  validator: (value) =>
                      (value ?? '').isEmpty ? 'Enter your password.' : null,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              if (message != null) ...[
                Semantics(
                  liveRegion: true,
                  child: Text(
                    message,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.colors.danger,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (showEmail)
                PrimaryButton(
                  label: 'Sign in',
                  isLoading:
                      state.isSubmitting && state.method == LoginMethod.email,
                  onPressed: state.isSubmitting ? null : _signInWithEmail,
                ),
              if (showEmail && showGoogle)
                const SizedBox(height: AppSpacing.md),
              if (showGoogle)
                OutlinedButton.icon(
                  onPressed: state.isSubmitting ? null : _signInWithGoogle,
                  icon: const Icon(Icons.login),
                  label: Text(
                    state.isSubmitting && state.method == LoginMethod.google
                        ? 'Signing in...'
                        : 'Continue with Google',
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
