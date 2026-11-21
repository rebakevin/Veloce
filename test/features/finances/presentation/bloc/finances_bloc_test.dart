import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:veloce/core/data/services/vehicle_lookup.dart';
import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/finances/domain/entities/finance_summary.dart';
import 'package:veloce/features/finances/domain/entities/finance_transaction.dart';
import 'package:veloce/features/finances/domain/enums/finance_period.dart';
import 'package:veloce/features/finances/domain/enums/finance_view_mode.dart';
import 'package:veloce/features/finances/domain/repositories/finances_repository.dart';
import 'package:veloce/features/finances/presentation/bloc/finances_bloc.dart';

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
    totalEarned: 150000,
    totalLosses: 20000,
    transactions: [
      FinanceTransaction(
        id: 'tx-1',
        bookingId: 'b-1',
        vehicleId: 'car-1',
        type: FinanceEntryType.earned,
        amount: 150000,
        date: DateTime(2026, 11, 10),
      ),
    ],
    carShares: const [],
  );

  setUp(() {
    repository = _MockFinancesRepository();
    session = _MockAuthSession();
    vehicleLookup = _MockVehicleLookup();

    when(() => vehicleLookup.byId(any()))
        .thenAnswer((_) async => const Result.failure(NotFoundFailure()));
    when(() => session.currentUserId).thenReturn('owner-1');
    when(
      () => repository.getOwnerFinances(
        ownerId: 'owner-1',
        period: any(named: 'period'),
        vehicleId: any(named: 'vehicleId'),
      ),
    ).thenAnswer((_) async => Result.success(testSummary));
  });

  FinancesBloc buildBloc({String? vehicleId}) => FinancesBloc(
    repository: repository,
    session: session,
    vehicleLookup: vehicleLookup,
    vehicleId: vehicleId,
  );

  group('FinancesBloc', () {
    test('initial state has default period and viewMode', () {
      final bloc = buildBloc();
      expect(bloc.state.status, FinancesStatus.initial);
      expect(bloc.state.period, FinancePeriod.thisMonth);
      expect(bloc.state.viewMode, FinanceViewMode.chart);
    });

    blocTest<FinancesBloc, FinancesState>(
      'FinancesStarted loads owner summary for thisMonth',
      build: buildBloc,
      act: (bloc) => bloc.add(const FinancesStarted()),
      expect: () => [
        const FinancesState(status: FinancesStatus.loading),
        FinancesState(
          status: FinancesStatus.loaded,
          period: FinancePeriod.thisMonth,
          viewMode: FinanceViewMode.chart,
          summary: testSummary,
        ),
      ],
      verify: (_) {
        verify(
          () => repository.getOwnerFinances(
            ownerId: 'owner-1',
            period: FinancePeriod.thisMonth,
            vehicleId: null,
          ),
        ).called(1);
      },
    );

    blocTest<FinancesBloc, FinancesState>(
      'FinancesStarted opens on the period it is given',
      build: buildBloc,
      act: (bloc) =>
          bloc.add(const FinancesStarted(period: FinancePeriod.thisYear)),
      verify: (bloc) {
        expect(bloc.state.period, FinancePeriod.thisYear);
        verify(
          () => repository.getOwnerFinances(
            ownerId: 'owner-1',
            period: FinancePeriod.thisYear,
            vehicleId: null,
          ),
        ).called(1);
      },
    );

    blocTest<FinancesBloc, FinancesState>(
      'FinancesPeriodChanged loads summary for the new period',
      build: buildBloc,
      act: (bloc) =>
          bloc.add(const FinancesPeriodChanged(FinancePeriod.thisYear)),
      expect: () => [
        const FinancesState(
          status: FinancesStatus.loading,
          period: FinancePeriod.thisYear,
        ),
        FinancesState(
          status: FinancesStatus.loaded,
          period: FinancePeriod.thisYear,
          viewMode: FinanceViewMode.chart,
          summary: testSummary,
        ),
      ],
      verify: (_) {
        verify(
          () => repository.getOwnerFinances(
            ownerId: 'owner-1',
            period: FinancePeriod.thisYear,
            vehicleId: null,
          ),
        ).called(1);
      },
    );

    blocTest<FinancesBloc, FinancesState>(
      'FinancesViewModeChanged toggles viewMode without refetching repository',
      build: buildBloc,
      act: (bloc) =>
          bloc.add(const FinancesViewModeChanged(FinanceViewMode.table)),
      expect: () => [const FinancesState(viewMode: FinanceViewMode.table)],
      verify: (_) {
        verifyNever(
          () => repository.getOwnerFinances(
            ownerId: any(named: 'ownerId'),
            period: any(named: 'period'),
            vehicleId: any(named: 'vehicleId'),
          ),
        );
      },
    );

    blocTest<FinancesBloc, FinancesState>(
      'FinancesRefreshed reloads summary',
      build: buildBloc,
      act: (bloc) => bloc.add(const FinancesRefreshed()),
      expect: () => [
        const FinancesState(status: FinancesStatus.loading),
        FinancesState(status: FinancesStatus.loaded, summary: testSummary),
      ],
    );
  });
}
