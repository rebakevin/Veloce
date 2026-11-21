import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/features/finances/domain/enums/finance_period.dart';
import 'package:veloce/features/finances/domain/enums/finance_view_mode.dart';

void main() {
  group('FinancePeriod and FinanceViewMode', () {
    test('FinancePeriod has thisMonth and thisYear with correct labels', () {
      expect(FinancePeriod.values.length, 2);
      expect(FinancePeriod.thisMonth.label, 'This month');
      expect(FinancePeriod.thisYear.label, 'This year');
    });

    test('FinancePeriod.fromName reads an enum name, defaults to month', () {
      expect(FinancePeriod.fromName('thisYear'), FinancePeriod.thisYear);
      expect(FinancePeriod.fromName('nonsense'), FinancePeriod.thisMonth);
      expect(FinancePeriod.fromName(null), FinancePeriod.thisMonth);
    });

    test('FinanceViewMode has chart and table with correct labels', () {
      expect(FinanceViewMode.values.length, 2);
      expect(FinanceViewMode.chart.label, 'Chart');
      expect(FinanceViewMode.table.label, 'Table');
    });
  });
}
