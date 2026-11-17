import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/theme/app_theme.dart';
import 'package:veloce/core/widgets/dialog_buttons.dart';

void main() {
  Future<void> pumpDialog(WidgetTester tester, {bool enabled = true}) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AlertDialog(
            title: const Text('Sure?'),
            actions: [
              DialogButtons(
                confirmLabel: 'Delete',
                onCancel: enabled ? () {} : null,
                onConfirm: enabled ? () {} : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('both buttons share one row and are the same width', (
    tester,
  ) async {
    await pumpDialog(tester);

    final cancel = tester.getRect(find.byType(OutlinedButton));
    final confirm = tester.getRect(find.byType(FilledButton));

    expect(cancel.width, confirm.width);
    expect(cancel.top, confirm.top);
    expect(cancel.right, lessThan(confirm.left));
  });

  testWidgets('a null callback disables the button', (tester) async {
    await pumpDialog(tester, enabled: false);

    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNull,
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });
}
