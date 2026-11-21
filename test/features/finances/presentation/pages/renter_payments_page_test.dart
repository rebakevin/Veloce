import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:veloce/core/domain/entities/ledger_entry.dart';
import 'package:veloce/core/domain/enums/party.dart';
import 'package:veloce/core/domain/enums/transaction_status.dart';
import 'package:veloce/core/domain/enums/transaction_type.dart';
import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/core/theme/app_theme.dart';
import 'package:veloce/features/finances/domain/entities/renter_payment_item.dart';
import 'package:veloce/features/finances/domain/enums/renter_payment_kind.dart';
import 'package:veloce/features/finances/domain/repositories/finances_repository.dart';
import 'package:veloce/features/finances/presentation/pages/renter_payments_page.dart';

class _MockFinancesRepository extends Mock implements FinancesRepository {}

class _MockAuthSession extends Mock implements AuthSession {}

void main() {
  late _MockFinancesRepository repository;
  late _MockAuthSession session;

  final testDate = DateTime(2026, 11, 10);
  final paymentItem = RenterPaymentItem(
    kind: RenterPaymentKind.payment,
    entry: LedgerEntry(
      id: 'tx-1',
      bookingId: 'b-1',
      vehicleId: 'car-1',
      ownerId: 'owner-1',
      renterId: 'renter-1',
      type: TransactionType.charge,
      amount: 310000,
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
    final getIt = GetIt.instance;
    getIt.reset();

    repository = _MockFinancesRepository();
    session = _MockAuthSession();

    when(() => session.currentUserId).thenReturn('renter-1');

    getIt.registerSingleton<FinancesRepository>(repository);
    getIt.registerSingleton<AuthSession>(session);
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  Widget buildWidget() {
    return MaterialApp(theme: AppTheme.light, home: const RenterPaymentsPage());
  }

  testWidgets(
    'renders payment history items with booking reference and amount',
    (tester) async {
      when(() => repository.getRenterPayments('renter-1'))
          .thenAnswer((_) async => Result.success([paymentItem]));

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('Payment history'), findsOneWidget);
      expect(find.text('VLC-0042'), findsOneWidget);
      expect(find.text('Toyota Vitz'), findsOneWidget);
      expect(find.text('Payment'), findsOneWidget);
      expect(find.text('Success'), findsOneWidget);
      expect(find.textContaining('-RWF 310,000'), findsOneWidget);
    },
  );

  testWidgets('renders empty state when there are no payments', (tester) async {
    when(() => repository.getRenterPayments('renter-1'))
        .thenAnswer((_) async => const Result.success([]));

    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    expect(find.text('No payment history'), findsOneWidget);
    expect(
      find.text(
        'Your rental payments, refunds and caution settlements will appear here.',
      ),
      findsOneWidget,
    );
  });
}
