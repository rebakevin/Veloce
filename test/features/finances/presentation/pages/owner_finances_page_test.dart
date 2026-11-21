import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:veloce/core/data/services/vehicle_lookup.dart';
import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/core/theme/app_theme.dart';
import 'package:veloce/features/finances/domain/entities/finance_summary.dart';
import 'package:veloce/features/finances/domain/entities/finance_transaction.dart';
import 'package:veloce/features/finances/domain/enums/finance_period.dart';
import 'package:veloce/features/finances/domain/repositories/finances_repository.dart';
import 'package:veloce/features/finances/presentation/pages/owner_finances_page.dart';

class _MockFinancesRepository extends Mock implements FinancesRepository {}

class _MockAuthSession extends Mock implements AuthSession {}

class _MockVehicleLookup extends Mock implements VehicleLookup {}

void main() {
  setUpAll(() {
    registerFallbackValue(FinancePeriod.thisMonth);
  });

  late _MockFinancesRepository repository;
  late _MockAuthSession session;
  late _MockVehicleLookup vehicleLookup;

  final testSummary = FinanceSummary(
    totalEarned: 180000,
    totalLosses: 30000,
    transactions: [
      FinanceTransaction(
        id: 'tx-1',
        bookingId: 'b-1',
        vehicleId: 'car-1',
        type: FinanceEntryType.earned,
        amount: 180000,
        date: DateTime(2026, 11, 10),
        vehicleName: 'Toyota Vitz',
        vehiclePlate: 'RAB 123 A',
      ),
      FinanceTransaction(
        id: 'tx-2',
        bookingId: 'b-2',
        vehicleId: 'car-1',
        type: FinanceEntryType.loss,
        amount: 30000,
        date: DateTime(2026, 11, 11),
        vehicleName: 'Toyota Vitz',
        vehiclePlate: 'RAB 123 A',
      ),
    ],
    carShares: const [],
  );

  setUp(() {
    final getIt = GetIt.instance;
    getIt.reset();

    repository = _MockFinancesRepository();
    session = _MockAuthSession();
    vehicleLookup = _MockVehicleLookup();

    when(() => session.currentUserId).thenReturn('owner-1');
    when(
      () => repository.getOwnerFinances(
        ownerId: 'owner-1',
        period: any(named: 'period'),
        vehicleId: any(named: 'vehicleId'),
      ),
    ).thenAnswer((_) async => Result.success(testSummary));

    getIt.registerSingleton<FinancesRepository>(repository);
    getIt.registerSingleton<AuthSession>(session);
    getIt.registerSingleton<VehicleLookup>(vehicleLookup);
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  Widget buildWidget({String? carId}) {
    return MaterialApp(
      theme: AppTheme.light,
      home: OwnerFinancesPage(carId: carId),
    );
  }

  testWidgets('renders title, period toggle, and two key figures', (
    tester,
  ) async {
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    expect(find.text('Finances'), findsOneWidget);
    expect(find.text('This month'), findsOneWidget);
    expect(find.text('This year'), findsOneWidget);
    expect(find.text('Total earned'), findsOneWidget);
    expect(find.text('Total losses'), findsOneWidget);
    expect(find.textContaining('180,000'), findsOneWidget);
    expect(find.textContaining('30,000'), findsOneWidget);
  });

  testWidgets('switching view mode to Table shows transaction rows', (
    tester,
  ) async {
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    expect(find.text('Table'), findsOneWidget);
    await tester.tap(find.text('Table'));
    await tester.pumpAndSettle();

    expect(find.text('Toyota Vitz'), findsNWidgets(2));
    expect(find.textContaining('+ RWF 180,000'), findsOneWidget);
    expect(find.textContaining('- RWF 30,000'), findsOneWidget);
  });

  testWidgets('chart view shows an empty state without transactions', (
    tester,
  ) async {
    when(
      () => repository.getOwnerFinances(
        ownerId: 'owner-1',
        period: any(named: 'period'),
        vehicleId: any(named: 'vehicleId'),
      ),
    ).thenAnswer(
      (_) async => const Result.success(
        FinanceSummary(
          totalEarned: 0,
          totalLosses: 0,
          transactions: [],
          carShares: [],
        ),
      ),
    );

    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    expect(find.text('No transactions in this period.'), findsOneWidget);
  });
}
