import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/theme/app_colors.dart';

double _contrast(Color a, Color b) {
  final lighter = a.computeLuminance() > b.computeLuminance() ? a : b;
  final darker = identical(lighter, a) ? b : a;
  return (lighter.computeLuminance() + 0.05) /
      (darker.computeLuminance() + 0.05);
}

void main() {
  const minimum = 4.5;

  for (final entry in {
    'light': AppColors.light,
    'dark': AppColors.dark,
  }.entries) {
    final colors = entry.value;
    final pairs = <String, (Color, Color)>{
      'ink on ground': (colors.ink, colors.ground),
      'ink on surface': (colors.ink, colors.surface),
      'body on ground': (colors.body, colors.ground),
      'body on surface': (colors.body, colors.surface),
      'muted on ground': (colors.muted, colors.ground),
      'muted on surface': (colors.muted, colors.surface),
      'brand on surface': (colors.brand, colors.surface),
      'brand on ground': (colors.brand, colors.ground),
      'onBrand on brand': (colors.onBrand, colors.brand),
      'brandDeep on brandWash': (colors.brandDeep, colors.brandWash),
      'brandDeep on brandTint': (colors.brandDeep, colors.brandTint),
      'inkSoft on sand': (colors.inkSoft, colors.sand),
      'danger on surface': (colors.danger, colors.surface),
      'danger on dangerWash': (colors.danger, colors.dangerWash),
      'cautionInk on cautionWash': (colors.cautionInk, colors.cautionWash),
      'cautionBody on cautionWash': (colors.cautionBody, colors.cautionWash),
      'reviewInk on reviewWash': (colors.reviewInk, colors.reviewWash),
    };
    for (final pair in pairs.entries) {
      test('${entry.key}: ${pair.key} is at least $minimum:1', () {
        expect(
          _contrast(pair.value.$1, pair.value.$2),
          greaterThanOrEqualTo(minimum),
        );
      });
    }
  }
}
