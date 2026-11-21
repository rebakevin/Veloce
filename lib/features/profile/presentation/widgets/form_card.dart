import 'package:flutter/material.dart';
import 'package:veloce/core/theme/app_spacing.dart';

/// White rounded card that holds a form's fields, spaced evenly.
class FormCard extends StatelessWidget {
  const FormCard({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < children.length; index++) ...[
              if (index > 0) const SizedBox(height: AppSpacing.lg),
              children[index],
            ],
          ],
        ),
      ),
    );
  }
}
