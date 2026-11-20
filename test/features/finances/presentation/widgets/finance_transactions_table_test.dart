import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/theme/app_theme.dart';
import 'package:veloce/features/finances/domain/entities/finance_transaction.dart';
import 'package:veloce/features/finances/presentation/widgets/finance_transactions_table.dart';

List<FinanceTransaction> _transactions(int count) => [
  for (var i = 0; i < count; i++)
    FinanceTransaction(
      id: 'tx-$i',
      bookingId: 'b-$i',
      vehicleId: 'car-1',
      type: FinanceEntryType.earned,
      amount: 1000,
      date: DateTime(2026, 11, 10),
      vehicleName: 'Car $i',
    ),
];

Future<void> _pump(
  WidgetTester tester,
  List<FinanceTransaction> transactions, {
  int? previewLimit = 5,
  VoidCallback? onViewAll,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SingleChildScrollView(
          child: FinanceTransactionsTable(
            transactions: transactions,
            previewLimit: previewLimit,
            onViewAll: onViewAll,
          ),
        ),
      ),
    ),
  );
}

void main() {
  final viewAll = find.textContaining('View all transactions');

  testWidgets('shows only 5 rows and the link when there are more than 5', (
    tester,
  ) async {
    var taps = 0;
    await _pump(tester, _transactions(7), onViewAll: () => taps++);

    expect(find.textContaining('Car '), findsNWidgets(5));
    expect(find.text('Car 5'), findsNothing);
    expect(find.text('View all transactions (7)'), findsOneWidget);

    await tester.tap(viewAll);
    expect(taps, 1);
  });

  testWidgets('exactly 5 rows shows all rows and no link', (tester) async {
    await _pump(tester, _transactions(5), onViewAll: () {});

    expect(find.textContaining('Car '), findsNWidgets(5));
    expect(viewAll, findsNothing);
  });

  testWidgets('fewer than 5 rows shows no link', (tester) async {
    await _pump(tester, _transactions(2), onViewAll: () {});

    expect(find.textContaining('Car '), findsNWidgets(2));
    expect(viewAll, findsNothing);
  });

  testWidgets('without a preview limit every row shows and no link', (
    tester,
  ) async {
    await _pump(tester, _transactions(8), previewLimit: null, onViewAll: () {});

    expect(find.textContaining('Car '), findsNWidgets(8));
    expect(viewAll, findsNothing);
  });

  testWidgets('shows an empty message with no transactions', (tester) async {
    await _pump(tester, const []);

    expect(find.text('No transactions in this period.'), findsOneWidget);
  });
}
