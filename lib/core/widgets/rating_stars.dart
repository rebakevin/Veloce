import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Read-only rating (star plus number), or an input when [onChanged] is set.
class RatingStars extends StatelessWidget {
  const RatingStars({super.key, this.rating, this.count, this.onChanged});

  final double? rating;
  final int? count;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    return onChanged == null ? _summary(context) : _input(context, onChanged);
  }

  Widget _summary(BuildContext context) {
    final colors = context.colors;
    final value = rating;
    final text = value == null || (count ?? 0) == 0
        ? 'New'
        : '${value.toStringAsFixed(1)} (${count ?? 0})';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: 18, color: colors.star),
        const SizedBox(width: 4),
        Text(text, style: AppTextStyles.caption.copyWith(color: colors.ink)),
      ],
    );
  }

  Widget _input(BuildContext context, ValueChanged<int> onChanged) {
    final colors = context.colors;
    final selected = (rating ?? 0).round();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var star = 1; star <= 5; star++)
          IconButton(
            tooltip: '$star star${star == 1 ? '' : 's'}',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: () => onChanged(star),
            icon: Icon(
              star <= selected
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              color: colors.star,
              size: 32,
            ),
          ),
      ],
    );
  }
}
