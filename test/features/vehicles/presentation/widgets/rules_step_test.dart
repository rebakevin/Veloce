import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/theme/app_theme.dart';
import 'package:veloce/features/vehicles/domain/entities/rules_pdf.dart';
import 'package:veloce/features/vehicles/domain/entities/wizard_draft.dart';
import 'package:veloce/features/vehicles/presentation/widgets/rules_pdf_picker.dart';
import 'package:veloce/features/vehicles/presentation/widgets/rules_step.dart';

import '../../domain/builders.dart';

class _FakePicker implements RulesPdfPicker {
  _FakePicker(this.result);
  final RulesPdf? result;

  @override
  Future<RulesPdf?> pick() async => result;
}

void main() {
  Future<List<WizardDraft>> pump(
    WidgetTester tester,
    WizardDraft draft,
    RulesPdf? picked,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 3000);
    addTearDown(tester.view.reset);
    final changes = <WizardDraft>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: RulesStep(
              draft: draft,
              errors: const {},
              onChanged: changes.add,
              pdfPicker: _FakePicker(picked),
            ),
          ),
        ),
      ),
    );
    return changes;
  }

  testWidgets('a picked PDF goes into the draft', (tester) async {
    final pdf = RulesPdf(bytes: Uint8List(10), name: 'rules.pdf');
    final changes = await pump(tester, aWizardDraft(), pdf);

    await tester.tap(find.text('Add a PDF (max 5 MB)'));
    await tester.pump();

    expect(changes.single.rulesPdf, pdf);
  });

  testWidgets('a PDF over 5 MB is refused with a message', (tester) async {
    final big = RulesPdf(
      bytes: Uint8List(RulesPdf.maxBytes + 1),
      name: 'big.pdf',
    );
    final changes = await pump(tester, aWizardDraft(), big);

    await tester.tap(find.text('Add a PDF (max 5 MB)'));
    await tester.pump();

    expect(changes, isEmpty);
    expect(find.textContaining('over 5 MB'), findsOneWidget);
  });

  testWidgets('the picked file name shows and Remove clears it', (
    tester,
  ) async {
    final draft = aWizardDraft().copyWith(
      rulesPdf: RulesPdf(bytes: Uint8List(1), name: 'rules.pdf'),
    );
    final changes = await pump(tester, draft, null);

    expect(find.text('rules.pdf'), findsOneWidget);
    expect(find.text('Replace PDF'), findsOneWidget);
    await tester.tap(find.text('Remove PDF'));

    expect(changes.single.rulesPdf, isNull);
    expect(changes.single.existingRulesUrl, isNull);
  });

  testWidgets('an existing PDF is mentioned in edit mode', (tester) async {
    final draft = aWizardDraft().copyWith(
      existingRulesUrl: 'https://files.test/r.pdf',
    );
    await pump(tester, draft, null);

    expect(find.text('This car already has a rules PDF.'), findsOneWidget);
  });
}
