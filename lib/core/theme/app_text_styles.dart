import 'package:flutter/material.dart';

/// Type scale from the design system, set in the bundled Figtree variable font.
abstract final class AppTextStyles {
  static const String fontFamily = 'Figtree';

  static const TextStyle display = TextStyle(
    fontFamily: fontFamily,
    fontSize: 34,
    height: 1.08,
    fontWeight: FontWeight.w800,
    letterSpacing: -1,
  );
  static const TextStyle title = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    height: 1.15,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.2,
  );
  static const TextStyle heading = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    height: 1.15,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.2,
  );
  static const TextStyle cardTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    height: 1.3,
    fontWeight: FontWeight.w800,
  );
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 1.5,
  );
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    height: 1.5,
  );
  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 1.45,
  );
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    height: 1.4,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 1.35,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 1,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle plate = TextStyle(
    fontSize: 22,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.3,
    fontFamily: 'monospace',
  );

  static TextTheme textTheme(Color ink, Color body) => TextTheme(
    displayLarge: display.copyWith(color: ink),
    headlineMedium: title.copyWith(color: ink),
    headlineSmall: heading.copyWith(color: ink),
    titleMedium: cardTitle.copyWith(color: ink),
    bodyLarge: bodyLarge.copyWith(color: body),
    bodyMedium: AppTextStyles.body.copyWith(color: body),
    bodySmall: bodySmall.copyWith(color: body),
    labelLarge: button.copyWith(color: ink),
    labelMedium: caption.copyWith(color: body),
    labelSmall: label.copyWith(color: body),
  );
}
