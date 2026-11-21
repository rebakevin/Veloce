import 'package:flutter/material.dart';

import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';

/// The square car placeholder at the left of a booking row.
class BookingThumb extends StatelessWidget {
  const BookingThumb({super.key, this.size = 84});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.brandWash,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(Icons.directions_car_outlined, color: colors.brand),
      ),
    );
  }
}
