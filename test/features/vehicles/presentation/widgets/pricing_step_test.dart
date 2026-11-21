import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/domain/entities/long_rate.dart';
import 'package:veloce/core/theme/app_theme.dart';
import 'package:veloce/features/vehicles/presentation/widgets/pricing_step.dart';

import '../../domain/builders.dart';

void main() {
  testWidgets('a tier shows its worked example and the 3-day preview', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 3000);
    addTearDown(tester.view.reset);
    final draft = aWizardDraft().copyWith(
      dailyPrice: 80000,
      longRates: const [LongRate(fromDays: 5, pricePerDay: 75000)],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: PricingStep(
              draft: draft,
              errors: const {},
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('5 days: 5 × '), findsOneWidget);
    expect(find.textContaining('375,000'), findsOneWidget);
    expect(find.text('Preview for 3 days'), findsOneWidget);
  });
}
