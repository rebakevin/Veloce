import 'package:flutter/material.dart';

/// Veloce palette from `docs/resources/DESIGN_SYSTEM.html`, with a dark variant.
/// Text pairs are contrast-checked in `test/core/theme/app_colors_test.dart`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.ground,
    required this.paper,
    required this.surface,
    required this.sand,
    required this.line,
    required this.disabled,
    required this.ink,
    required this.inkSoft,
    required this.body,
    required this.muted,
    required this.brand,
    required this.brandDeep,
    required this.brandWash,
    required this.brandTint,
    required this.onBrand,
    required this.danger,
    required this.dangerAction,
    required this.dangerWash,
    required this.cautionWash,
    required this.cautionInk,
    required this.cautionBody,
    required this.star,
    required this.reviewWash,
    required this.reviewInk,
    required this.scrim,
  });

  static const AppColors light = AppColors(
    ground: Color(0xFFF6F2E9),
    paper: Color(0xFFFAF8F3),
    surface: Color(0xFFFFFFFF),
    sand: Color(0xFFE7E2D6),
    line: Color(0xFFD9D4C8),
    disabled: Color(0xFFC9C4B8),
    ink: Color(0xFF1A1814),
    inkSoft: Color(0xFF3D3A33),
    body: Color(0xFF4F4B43),
    muted: Color(0xFF6B665C),
    brand: Color(0xFF3B5683),
    brandDeep: Color(0xFF2E4568),
    brandWash: Color(0xFFE9EDF3),
    brandTint: Color(0xFFDFE5EE),
    onBrand: Color(0xFFFFFFFF),
    danger: Color(0xFF9B1C1C),
    dangerAction: Color(0xFFC62F2F),
    dangerWash: Color(0xFFFADCDC),
    cautionWash: Color(0xFFFFF0C2),
    cautionInk: Color(0xFF6B4A00),
    cautionBody: Color(0xFF5C4300),
    star: Color(0xFFE8A317),
    reviewWash: Color(0xFFE5DEF5),
    reviewInk: Color(0xFF4A2E85),
    scrim: Color(0x801A1814),
  );

  static const AppColors dark = AppColors(
    ground: Color(0xFF15130F),
    paper: Color(0xFF1B1915),
    surface: Color(0xFF211F1A),
    sand: Color(0xFF2E2B24),
    line: Color(0xFF5A5649),
    disabled: Color(0xFF4A463C),
    ink: Color(0xFFF4F0E6),
    inkSoft: Color(0xFFDDD8CB),
    body: Color(0xFFCBC6B8),
    muted: Color(0xFFA9A496),
    brand: Color(0xFF9DB5DE),
    brandDeep: Color(0xFFBFD0EC),
    brandWash: Color(0xFF232B3A),
    brandTint: Color(0xFF2B3650),
    onBrand: Color(0xFF101828),
    danger: Color(0xFFF4A3A3),
    dangerAction: Color(0xFFEE7070),
    dangerWash: Color(0xFF3B1C1C),
    cautionWash: Color(0xFF3A2F10),
    cautionInk: Color(0xFFF5D77A),
    cautionBody: Color(0xFFEBD28C),
    star: Color(0xFFE8A317),
    reviewWash: Color(0xFF2E2548),
    reviewInk: Color(0xFFD3C4F4),
    scrim: Color(0xB3000000),
  );

  final Color ground;
  final Color paper;
  final Color surface;
  final Color sand;
  final Color line;
  final Color disabled;
  final Color ink;
  final Color inkSoft;
  final Color body;
  final Color muted;
  final Color brand;
  final Color brandDeep;
  final Color brandWash;
  final Color brandTint;
  final Color onBrand;
  final Color danger;
  final Color dangerAction;
  final Color dangerWash;
  final Color cautionWash;
  final Color cautionInk;
  final Color cautionBody;
  final Color star;
  final Color reviewWash;
  final Color reviewInk;
  final Color scrim;

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) =>
      t < 0.5 || other is! AppColors ? this : other;
}

extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
