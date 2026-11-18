import 'package:flutter/material.dart';

import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';

/// Terms gate shared by the car detail and request review screens.
class BookingTerms extends StatelessWidget {
  const BookingTerms({
    required this.accepted,
    required this.onChanged,
    super.key,
  });

  final bool accepted;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: accepted,
      onChanged: (value) => onChanged(value ?? false),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      title: const Text(
        'I agree to the owner’s rules and the Veloce rental terms.',
        style: AppTextStyles.bodySmall,
      ),
      subtitle: const Text('Self-drive only. The caution fee is refundable.'),
      secondary: const Padding(
        padding: EdgeInsets.only(left: AppSpacing.sm),
        child: Icon(Icons.gavel_outlined),
      ),
    );
  }
}
