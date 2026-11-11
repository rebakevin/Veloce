import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:veloce/core/domain/enums/auth_provider_kind.dart';
import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/features/auth/auth.dart';
import 'package:veloce/features/profile/presentation/bloc/accounts_bloc.dart';
import 'package:veloce/features/profile/presentation/pages/accounts_page.dart';

import 'profile_page_harness.dart';

class _MockAccountsBloc extends MockBloc<AccountsEvent, AccountsState>
    implements AccountsBloc {}

void main() {
  const renter = LinkedAccount(
    uid: 'r1',
    email: 'r1@example.com',
    name: 'Rita Renter',
    role: UserRole.renter,
    authType: AuthProviderKind.password,
  );
  const owner = LinkedAccount(
    uid: 'o1',
    email: 'o1@example.com',
    name: 'Omar Owner',
    role: UserRole.owner,
    authType: AuthProviderKind.google,
  );
  const loaded = AccountsLoaded(accounts: [renter, owner], currentUid: 'r1');

  late _MockAccountsBloc bloc;

  setUpAll(() => registerFallbackValue(const AccountsStarted()));

  setUp(() {
    bloc = _MockAccountsBloc();
    when(() => bloc.isClosed).thenReturn(false);
  });

  tearDown(resetGetIt);

  Future<void> pumpAccounts(
    WidgetTester tester, {
    Stream<AccountsState> states = const Stream.empty(),
  }) async {
    whenListen(bloc, states, initialState: loaded);
    final router = testRouter(
      home: BlocProvider<AccountsBloc>.value(
        value: bloc,
        child: const AccountsView(),
      ),
      stubs: [RouteNames.ownerHome, RouteNames.profileAccountsAdd],
    );
    await tester.pumpWidget(routerApp(router, registerMessenger()));
  }

  testWidgets('lists roles and marks only the current account', (tester) async {
    await pumpAccounts(tester);

    expect(find.text('Rita Renter'), findsOneWidget);
    expect(find.text('Omar Owner'), findsOneWidget);
    expect(find.text('Renter'), findsOneWidget);
    expect(find.text('Car owner'), findsOneWidget);
    expect(find.text('Current'), findsOneWidget);
  });

  testWidgets('tapping another account dispatches a switch', (tester) async {
    await pumpAccounts(tester);

    await tester.tap(find.text('Omar Owner'));
    verify(() => bloc.add(const AccountsSwitchRequested('o1'))).called(1);

    await tester.tap(find.text('Rita Renter'));
    verifyNever(() => bloc.add(const AccountsSwitchRequested('r1')));
  });

  testWidgets('removing asks for confirmation first', (tester) async {
    await pumpAccounts(tester);

    await tester.tap(find.byTooltip('Remove Omar Owner from this device'));
    await tester.pumpAndSettle();
    verifyNever(() => bloc.add(const AccountsRemoveRequested('o1')));

    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    verify(() => bloc.add(const AccountsRemoveRequested('o1'))).called(1);
  });

  testWidgets('a finished switch goes to the target role home', (tester) async {
    await pumpAccounts(
      tester,
      states: Stream.value(
        loaded.copyWith(status: AccountsStatus.switched, target: owner),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('stub ${RouteNames.ownerHome}'), findsOneWidget);
    verify(() => bloc.add(const AccountsResultAcknowledged())).called(1);
  });
}
