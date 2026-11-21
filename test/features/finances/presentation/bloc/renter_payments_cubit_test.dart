import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:veloce/core/domain/entities/ledger_entry.dart';
import 'package:veloce/core/domain/enums/party.dart';
import 'package:veloce/core/domain/enums/transaction_status.dart';
import 'package:veloce/core/domain/enums/transaction_type.dart';
import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/finances/domain/entities/renter_payment_item.dart';
import 'package:veloce/features/finances/domain/enums/renter_payment_kind.dart';
import 'package:veloce/features/finances/domain/repositories/finances_repository.dart';
import 'package:veloce/features/finances/presentation/bloc/renter_payments_cubit.dart';

class _MockFinancesRepository extends Mock implements FinancesRepository {}

class _MockAuthSession extends Mock implements AuthSession {}

void main() {
  late _MockFinancesRepository repository;
  late _MockAuthSession session;

  final testDate = DateTime(2026, 11, 10);
  final item = RenterPaymentItem(
    kind: RenterPaymentKind.payment,
    entry: LedgerEntry(
      id: 'tx-1',
      bookingId: 'b-1',
      vehicleId: 'car-1',
      ownerId: 'owner-1',
      renterId: 'renter-1',
      type: TransactionType.charge,
      amount: 210000,
      fromParty: Party.renter,
      toParty: Party.veloce,
      reference: 'MOMO-1',
      status: TransactionStatus.success,
      at: testDate,
    ),
    bookingReference: 'VLC-0042',
    vehicleName: 'Toyota Vitz',
  );

  setUp(() {
    repository = _MockFinancesRepository();
    session = _MockAuthSession();

    when(() => session.currentUserId).thenReturn('renter-1');
  });

  RenterPaymentsCubit buildCubit() =>
      RenterPaymentsCubit(repository: repository, session: session);

  group('RenterPaymentsCubit', () {
    test('initial state is RenterPaymentsLoading', () {
      expect(buildCubit().state, equals(const RenterPaymentsLoading()));
    });

    blocTest<RenterPaymentsCubit, RenterPaymentsState>(
      'load emits RenterPaymentsLoaded when transactions exist',
      setUp: () {
        when(() => repository.getRenterPayments('renter-1'))
            .thenAnswer((_) async => Result.success([item]));
      },
      build: buildCubit,
      act: (cubit) => cubit.load(),
      expect: () => [
        const RenterPaymentsLoading(),
        RenterPaymentsLoaded([item]),
      ],
    );

    blocTest<RenterPaymentsCubit, RenterPaymentsState>(
      'load emits RenterPaymentsEmpty when list is empty',
      setUp: () {
        when(() => repository.getRenterPayments('renter-1'))
            .thenAnswer((_) async => const Result.success([]));
      },
      build: buildCubit,
      act: (cubit) => cubit.load(),
      expect: () => [
        const RenterPaymentsLoading(),
        const RenterPaymentsEmpty(),
      ],
    );

    blocTest<RenterPaymentsCubit, RenterPaymentsState>(
      'load emits RenterPaymentsFailure when repository fails',
      setUp: () {
        when(() => repository.getRenterPayments('renter-1'))
            .thenAnswer((_) async => const Result.failure(NetworkFailure()));
      },
      build: buildCubit,
      act: (cubit) => cubit.load(),
      expect: () => [
        const RenterPaymentsLoading(),
        const RenterPaymentsFailure(NetworkFailure()),
      ],
    );
  });
}
