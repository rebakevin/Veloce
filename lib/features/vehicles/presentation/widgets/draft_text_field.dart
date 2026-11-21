import 'package:flutter/material.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';

int parseWhole(String text) =>
    int.tryParse(text.replaceAll(RegExp('[^0-9]'), '')) ?? 0;

class DraftTextField extends StatefulWidget {
  const DraftTextField({
    required this.label,
    required this.hint,
    required this.onChanged,
    super.key,
    this.initialValue = '',
    this.errorText,
    this.keyboardType,
    this.maxLines = 1,
    this.enabled = true,
  });

  final String label;
  final String hint;
  final ValueChanged<String> onChanged;
  final String initialValue;
  final String? errorText;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool enabled;

  @override
  State<DraftTextField> createState() => _DraftTextFieldState();
}

class _DraftTextFieldState extends State<DraftTextField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: AppTextStyles.caption),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _controller,
          keyboardType: widget.keyboardType,
          maxLines: widget.maxLines,
          enabled: widget.enabled,
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            hintText: widget.hint,
            errorText: widget.errorText,
          ),
        ),
      ],
    );
  }
}
