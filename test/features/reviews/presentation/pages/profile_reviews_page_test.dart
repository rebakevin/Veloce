import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:veloce/core/data/services/user_lookup.dart';
import 'package:veloce/core/data/services/vehicle_lookup.dart';
import 'package:veloce/core/domain/entities/review.dart';
import 'package:veloce/core/domain/enums/subject_type.dart';
import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/core/theme/app_theme.dart';
import 'package:veloce/core/widgets/empty_state.dart';
import 'package:veloce/core/widgets/error_view.dart';
import 'package:veloce/features/reviews/domain/repositories/review_repository.dart';
import 'package:veloce/features/reviews/presentation/pages/profile_reviews_page.dart';
import 'package:veloce/features/reviews/presentation/widgets/review_card.dart';

import '../../../../support/builders.dart';

class _MockReviewRepository extends Mock implements ReviewRepository {}

class _MockUserLookup extends Mock implements UserLookup {}

class _MockVehicleLookup extends Mock implements VehicleLookup {}

class _MockAuthSession extends Mock implements AuthSession {}

void main() {
  late _MockReviewRepository repository;
  late _MockUserLookup userLookup;
  late _MockVehicleLookup vehicleLookup;
  late _MockAuthSession session;

  final testReview = Review(
    id: 'r1',
    bookingId: 'b1',
    authorId: 'user_1',
    subjectType: SubjectType.vehicle,
    subjectId: 'car-1',
    stars: 5,
    comment: 'Exceptional driving experience!',
    createdAt: DateTime(2026, 11, 15),
    editedAt: null,
  );

  final testVehicle = aVehicle();

  setUp(() {
    final getIt = GetIt.instance;
    getIt.reset();

    repository = _MockReviewRepository();
    userLookup = _MockUserLookup();
    vehicleLookup = _MockVehicleLookup();
    session = _MockAuthSession();

    when(() => session.currentUserId).thenReturn('user_1');
    when(() => vehicleLookup.byId('car-1'))
        .thenAnswer((_) async => Result.success(testVehicle));
    when(() => userLookup.byId(any()))
        .thenAnswer((_) async => const Result.failure(NotFoundFailure()));

    getIt.registerSingleton<ReviewRepository>(repository);
    getIt.registerSingleton<UserLookup>(userLookup);
    getIt.registerSingleton<VehicleLookup>(vehicleLookup);
    getIt.registerSingleton<AuthSession>(session);
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  Widget buildTestableWidget() {
    return MaterialApp(theme: AppTheme.light, home: const ProfileReviewsPage());
  }

  group('ProfileReviewsPage', () {
    testWidgets('renders empty state when no reviews written', (tester) async {
      when(() => repository.getReviewsByAuthor('user_1'))
          .thenAnswer((_) async => const Result.success([]));

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('My reviews'), findsOneWidget);
      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('No reviews written'), findsOneWidget);
    });

    testWidgets('renders review cards when reviews exist', (tester) async {
      when(() => repository.getReviewsByAuthor('user_1'))
          .thenAnswer((_) async => Result.success([testReview]));

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.byType(ReviewCard), findsOneWidget);
      expect(find.text('For Toyota Vitz'), findsOneWidget);
      expect(find.text('Exceptional driving experience!'), findsOneWidget);
    });

    testWidgets('renders error view when repository fails', (tester) async {
      when(() => repository.getReviewsByAuthor('user_1')).thenAnswer(
        (_) async => const Result.failure(UnknownFailure('Connection error')),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text('Connection error'), findsOneWidget);
    });
  });
}
