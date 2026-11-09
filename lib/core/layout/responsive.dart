import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Layout helpers so every screen adapts to small phones, large phones and
/// landscape without fixed sizes.
abstract final class Responsive {
  /// Widest column of content; keeps landscape and tablets readable.
  static const double maxContentWidth = 640;

  static bool isLandscape(BuildContext context) =>
      MediaQuery.orientationOf(context) == Orientation.landscape;

  static bool isCompactWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 360;

  /// Horizontal padding that centres content wider than [maxContentWidth].
  static EdgeInsets pagePadding(BuildContext context) {
    final extra = (MediaQuery.sizeOf(context).width - maxContentWidth) / 2;
    final horizontal = extra > AppSpacing.gutter ? extra : AppSpacing.gutter;
    return EdgeInsets.symmetric(horizontal: horizontal);
  }
}
