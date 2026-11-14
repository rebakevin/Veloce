import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/features/profile/presentation/bloc/delete_account_cubit.dart';
import 'package:veloce/features/profile/presentation/widgets/delete_account_dialog.dart';

class _MockCubit extends MockCubit<DeleteAccountState>
    implements DeleteAccountCubit {}

void main() {
  late _MockCubit cubit;

  setUp(() {
    cubit = _MockCubit();
    when(() => cubit.state).thenReturn(const DeleteAccountIdle());
    when(() => cubit.delete(password: any(named: 'password')))
        .thenAnswer((_) async {});
  });

  Future<void> pumpDialog(WidgetTester tester, {required bool needsPassword}) {
    return tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<DeleteAccountCubit>.value(
          value: cubit,
          child: DeleteAccountDialog(needsPassword: needsPassword),
        ),
      ),
    );
  }

  testWidgets('sends the typed password for an email account', (tester) async {
    await pumpDialog(tester, needsPassword: true);

    await tester.enterText(find.byType(TextField), 'secret123');
    await tester.tap(find.text('Delete account'));

    verify(() => cubit.delete(password: 'secret123')).called(1);
  });

  testWidgets('a Google account has no password field', (tester) async {
    await pumpDialog(tester, needsPassword: false);

    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.text('Delete account'));

    verify(() => cubit.delete()).called(1);
  });

  testWidgets('shows the failure and keeps the buttons enabled', (
    tester,
  ) async {
    when(() => cubit.state).thenReturn(
      const DeleteAccountFailure(ValidationFailure('Wrong email or password.')),
    );
    await pumpDialog(tester, needsPassword: true);

    expect(find.text('Wrong email or password.'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('disables the buttons while deleting', (tester) async {
    when(() => cubit.state).thenReturn(const DeleteAccountRunning());
    await pumpDialog(tester, needsPassword: true);

    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });
}
