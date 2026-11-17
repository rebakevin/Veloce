import 'dart:convert';
import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:veloce/core/domain/entities/document_photo.dart';
import 'package:veloce/core/domain/enums/auth_provider_kind.dart';
import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/theme/app_theme.dart';
import 'package:veloce/core/widgets/photo_picker.dart';
import 'package:veloce/features/auth/domain/entities/auth_user.dart';
import 'package:veloce/features/auth/presentation/bloc/register_bloc.dart';
import 'package:veloce/features/auth/presentation/bloc/register_draft.dart';
import 'package:veloce/features/auth/presentation/pages/register_details_page.dart';

import '../../domain/auth_fakes.dart';

class _MockRegisterBloc extends MockBloc<RegisterEvent, RegisterState>
    implements RegisterBloc {}

/// A valid 1x1 image, so the tile can decode what was picked.
final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

class _FakePhotoPicker implements PhotoPicker {
  const _FakePhotoPicker(this.photo);

  final DocumentPhoto photo;

  @override
  Future<DocumentPhoto?> pick(BuildContext context) async => photo;
}

void main() {
  late _MockRegisterBloc bloc;

  setUpAll(() => registerFallbackValue(const RegisterDetailsSubmitted()));

  setUp(() {
    bloc = _MockRegisterBloc();
    final getIt = GetIt.instance;
    if (!getIt.isRegistered<Clock>()) {
      getIt.registerSingleton<Clock>(const FixedClock());
    }
  });

  tearDown(() => GetIt.instance.reset());

  Future<void> pumpDetails(
    WidgetTester tester,
    RegisterState state, {
    PhotoPicker? pickPhoto,
  }) async {
    when(() => bloc.state).thenReturn(state);
    whenListen(bloc, const Stream<RegisterState>.empty(), initialState: state);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BlocProvider<RegisterBloc>.value(
          value: bloc,
          child: RegisterDetailsPage(
            pickPhoto: pickPhoto ?? const ImagePickerPhotoPicker(),
          ),
        ),
      ),
    );
  }

  RegisterState renterState({
    Map<RegisterField, String> errors = const {},
    AuthUser? google,
  }) => RegisterState(
    step: RegisterStep.details,
    draft: const RegisterDraft(role: UserRole.renter),
    fieldErrors: errors,
    googleUser: google,
  );

  testWidgets('every field with its error fits a small phone at large text', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(320, 568)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpDetails(
      tester,
      renterState(
        errors: {
          RegisterField.name: 'Name is required.',
          RegisterField.phone: 'Enter your phone number.',
          RegisterField.email: 'Enter your email address.',
          RegisterField.password: 'Enter a password.',
          RegisterField.dateOfBirth: 'Choose your date of birth.',
          RegisterField.documentNumber: 'Licence number is required.',
          RegisterField.licenceExpiry: 'Choose the licence expiry date.',
          RegisterField.photo: 'Add a photo of your document.',
        },
      ),
    );
    await tester.scrollUntilVisible(
      find.text('Add a photo of your document.'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('shows an inline message under every invalid field', (
    tester,
  ) async {
    await pumpDetails(
      tester,
      renterState(
        errors: {
          RegisterField.name: 'Name is required.',
          RegisterField.phone: 'Enter your phone number.',
          RegisterField.email: 'Enter your email address.',
          RegisterField.password: 'Enter a password.',
          RegisterField.dateOfBirth: 'Choose your date of birth.',
          RegisterField.documentNumber: 'Licence number is required.',
          RegisterField.licenceExpiry: 'Choose the licence expiry date.',
          RegisterField.photo: 'Add a photo of your document.',
        },
      ),
    );
    await tester.scrollUntilVisible(
      find.text('Add a photo of your document.'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    for (final message in [
      'Name is required.',
      'Enter your phone number.',
      'Enter your email address.',
      'Enter a password.',
      'Choose your date of birth.',
      'Licence number is required.',
      'Choose the licence expiry date.',
      'Add a photo of your document.',
    ]) {
      expect(find.text(message), findsOneWidget, reason: message);
    }
  });

  testWidgets('Continue sends a submit to the bloc, which validates', (
    tester,
  ) async {
    await pumpDetails(tester, renterState());

    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));

    verify(() => bloc.add(const RegisterDetailsSubmitted())).called(1);
  });

  testWidgets('typing sends the edit to the bloc', (tester) async {
    await pumpDetails(tester, renterState());

    await tester.enterText(find.byType(TextField).first, 'Aline');

    verify(() => bloc.add(const RegisterDraftEdited(name: 'Aline'))).called(1);
  });

  testWidgets('a Google sign-up hides email and password', (tester) async {
    await pumpDetails(
      tester,
      renterState(google: anAuthUser(provider: AuthProviderKind.google)),
    );

    expect(find.text('Email'), findsNothing);
    expect(find.text('Password'), findsNothing);
    expect(find.text('Create account'), findsWidgets);
  });

  testWidgets('an owner is asked for a National ID, not a licence', (
    tester,
  ) async {
    await pumpDetails(
      tester,
      const RegisterState(
        step: RegisterStep.details,
        draft: RegisterDraft(role: UserRole.owner),
      ),
    );

    expect(find.text('National ID number'), findsOneWidget);
    expect(find.text('Driving licence number'), findsNothing);
    expect(find.text('Licence expiry date'), findsNothing);
  });

  testWidgets('a picked photo goes to the bloc', (tester) async {
    await pumpDetails(
      tester,
      renterState(),
      pickPhoto: _FakePhotoPicker(DocumentPhoto(bytes: _png, extension: 'png')),
    );

    await tester.scrollUntilVisible(
      find.text('Photo of your driving licence'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Photo of your driving licence'));
    await tester.pump();

    verify(
      () => bloc.add(
        RegisterDraftEdited(photoBytes: _png, photoExtension: 'png'),
      ),
    ).called(1);
  });

  testWidgets('a failed final write offers Retry', (tester) async {
    await pumpDetails(
      tester,
      const RegisterState(
        step: RegisterStep.submitting,
        status: RegisterStatus.failure,
        message: 'We could not verify this document. Try again.',
        draft: RegisterDraft(role: UserRole.renter),
      ),
    );

    expect(
      find.text('We could not verify this document. Try again.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Try again'));
    verify(() => bloc.add(const RegisterSubmitRetried())).called(1);
  });
}
