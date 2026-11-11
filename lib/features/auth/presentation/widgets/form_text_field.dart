import 'package:flutter/material.dart';

import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';

/// Labelled text field that shows an inline [errorText] under the input. The
/// message comes from the bloc state (the validators run there), so unlike
/// `AppTextField` it needs no `Form`.
class FormTextField extends StatelessWidget {
  const FormTextField({
    required this.label,
    required this.controller,
    super.key,
    this.errorText,
    this.hint,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
    this.obscureText = false,
    this.suffix,
    this.enabled = true,
    this.maxLength,
  });

  final String label;
  final TextEditingController controller;
  final String? errorText;
  final String? hint;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool obscureText;
  final Widget? suffix;
  final bool enabled;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          obscureText: obscureText,
          maxLength: maxLength,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            errorMaxLines: 3,
            suffixIcon: suffix,
            counterText: '',
          ),
        ),
      ],
    );
  }
}
