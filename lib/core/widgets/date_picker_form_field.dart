import 'package:flutter/material.dart';

import 'date_picker_field.dart';

/// [DatePickerField] as a form field with a validator. [value] holds the
/// chosen date for the page.
class DatePickerFormField extends StatelessWidget {
  const DatePickerFormField({
    required this.label,
    required this.value,
    required this.firstDate,
    required this.lastDate,
    super.key,
    this.validator,
  });

  final String label;
  final ValueNotifier<DateTime?> value;
  final DateTime firstDate;
  final DateTime lastDate;
  final String? Function(DateTime? value)? validator;

  @override
  Widget build(BuildContext context) {
    return FormField<DateTime>(
      initialValue: value.value,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      builder: (field) => DatePickerField(
        label: label,
        value: field.value,
        firstDate: firstDate,
        lastDate: lastDate,
        errorText: field.errorText,
        onChanged: (picked) {
          value.value = picked;
          field.didChange(picked);
        },
      ),
    );
  }
}
