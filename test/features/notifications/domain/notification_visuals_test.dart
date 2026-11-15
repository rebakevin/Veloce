import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/domain/enums/notification_type.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/features/notifications/presentation/widgets/notification_tile.dart';

void main() {
  group('NotificationType', () {
    test('has 12 distinct types with valid keys and labels', () {
      expect(NotificationType.values.length, 12);
      final keys = NotificationType.values.map((t) => t.key).toSet();
      expect(keys.length, 12);
      for (final type in NotificationType.values) {
        expect(type.key, isNotEmpty);
        expect(type.label, isNotEmpty);
        expect(NotificationType.fromKey(type.key), equals(type));
      }
    });

    test('fromKey throws for unknown key', () {
      expect(
        () => NotificationType.fromKey('unknown_type'),
        throwsArgumentError,
      );
    });
  });

  group('NotificationVisuals', () {
    test(
      'provides icon and colors for every NotificationType in light theme',
      () {
        const colors = AppColors.light;
        for (final type in NotificationType.values) {
          final visuals = NotificationVisuals.forType(type, colors);
          expect(visuals.icon, isA<IconData>());
          expect(visuals.backgroundColor, isA<Color>());
          expect(visuals.iconColor, isA<Color>());
        }
      },
    );

    test(
      'provides icon and colors for every NotificationType in dark theme',
      () {
        const colors = AppColors.dark;
        for (final type in NotificationType.values) {
          final visuals = NotificationVisuals.forType(type, colors);
          expect(visuals.icon, isA<IconData>());
          expect(visuals.backgroundColor, isA<Color>());
          expect(visuals.iconColor, isA<Color>());
        }
      },
    );
  });
}
