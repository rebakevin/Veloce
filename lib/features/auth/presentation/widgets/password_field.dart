import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'form_text_field.dart';
import 'obscure_cubit.dart';

/// [FormTextField] for a password with a show/hide toggle.
class PasswordField extends StatelessWidget {
  const PasswordField({
    required this.controller,
    required this.hint,
    super.key,
    this.label = 'Password',
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.autofillHints = const [AutofillHints.password],
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final Iterable<String> autofillHints;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ObscureCubit(),
      child: BlocBuilder<ObscureCubit, bool>(
        builder: (context, obscured) => FormTextField(
          label: label,
          hint: hint,
          controller: controller,
          errorText: errorText,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          obscureText: obscured,
          suffix: IconButton(
            tooltip: obscured ? 'Show password' : 'Hide password',
            icon: Icon(
              obscured
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
            onPressed: context.read<ObscureCubit>().toggle,
          ),
        ),
      ),
    );
  }
}
