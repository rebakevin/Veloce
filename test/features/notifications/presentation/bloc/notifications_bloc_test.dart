import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:veloce/core/data/services/preferences_service.dart';
import 'package:veloce/core/domain/entities/app_notification.dart';
import 'package:veloce/core/domain/enums/notification_type.dart';
import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:veloce/features/notifications/presentation/bloc/notifications_bloc.dart';

class _MockNotificationsRepository extends Mock
    implements NotificationsRepository {}

class _MockAuthSession extends Mock implements AuthSession {}

class _MockPreferencesService extends Mock implements PreferencesService {}

void main() {
  late _MockNotificationsRepository repository;
  late _MockAuthSession session;
  late _MockPreferencesService preferences;
  late StreamController<List<AppNotification>> notifsController;
  late StreamController<void> sessionChangesController;
  late StreamController<bool> prefChangesController;

  final testDate = DateTime(2026, 11, 15, 10);
  final notif1 = AppNotification(
    id: 'n-1',
    userId: 'user-1',
    type: NotificationType.requestReceived,
    title: 'Request 1',
    text: 'Text 1',
    bookingId: 'b-1',
    read: false,
    createdAt: testDate,
  );
  final notif2 = AppNotification(
    id: 'n-2',
    userId: 'user-1',
    type: NotificationType.requestApproved,
    title: 'Request 2',
    text: 'Text 2',
    bookingId: 'b-2',
    read: true,
    createdAt: testDate,
  );

  setUp(() {
    repository = _MockNotificationsRepository();
    session = _MockAuthSession();
    preferences = _MockPreferencesService();

    notifsController = StreamController<List<AppNotification>>.broadcast();
    sessionChangesController = StreamController<void>.broadcast();
    prefChangesController = StreamController<bool>.broadcast();

    when(() => session.currentUserId).thenReturn('user-1');
    when(() => session.changes)
        .thenAnswer((_) => sessionChangesController.stream);
    when(() => preferences.notificationsEnabled).thenReturn(true);
    when(() => preferences.notificationsEnabledChanges)
        .thenAnswer((_) => prefChangesController.stream);
    when(() => repository.watchNotifications('user-1'))
        .thenAnswer((_) => notifsController.stream);
  });

  tearDown(() {
    notifsController.close();
    sessionChangesController.close();
    prefChangesController.close();
  });

  NotificationsBloc buildBloc() => NotificationsBloc(
    repository: repository,
    session: session,
    preferences: preferences,
  );

  group('NotificationsBloc', () {
    test('initial state is NotificationsInitial', () {
      expect(buildBloc().state, equals(const NotificationsInitial()));
    });

    blocTest<NotificationsBloc, NotificationsState>(
      'subscribes to notifications stream and computes unreadCount correctly',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const NotificationsStarted());
        await Future<void>.delayed(Duration.zero);
        notifsController.add([notif1, notif2]);
      },
      expect: () => [
        const NotificationsLoading(),
        NotificationsLoaded(
          notifications: [notif1, notif2],
          unreadCount: 1,
          notificationsEnabled: true,
        ),
      ],
    );

    blocTest<NotificationsBloc, NotificationsState>(
      'emits empty state when user has no notifications',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const NotificationsStarted());
        await Future<void>.delayed(Duration.zero);
        notifsController.add([]);
      },
      expect: () => [
        const NotificationsLoading(),
        const NotificationsEmpty(notificationsEnabled: true),
      ],
    );

    blocTest<NotificationsBloc, NotificationsState>(
      'emits disabled state when notifications are turned off in preferences',
      setUp: () {
        when(() => preferences.notificationsEnabled).thenReturn(false);
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const NotificationsStarted());
        await Future<void>.delayed(Duration.zero);
        notifsController.add([notif1]);
      },
      expect: () => [
        const NotificationsLoading(),
        const NotificationsLoaded(
          notifications: [],
          unreadCount: 0,
          notificationsEnabled: false,
        ),
      ],
    );

    blocTest<NotificationsBloc, NotificationsState>(
      'markAsRead delegates to repository',
      setUp: () {
        when(() => repository.markAsRead('n-1'))
            .thenAnswer((_) async => const Result.success(null));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const NotificationMarkReadRequested('n-1')),
      verify: (_) {
        verify(() => repository.markAsRead('n-1')).called(1);
      },
    );

    blocTest<NotificationsBloc, NotificationsState>(
      'markAllAsRead delegates to repository for current user',
      setUp: () {
        when(() => repository.markAllAsRead('user-1'))
            .thenAnswer((_) async => const Result.success(null));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const NotificationMarkAllReadRequested()),
      verify: (_) {
        verify(() => repository.markAllAsRead('user-1')).called(1);
      },
    );

    blocTest<NotificationsBloc, NotificationsState>(
      'deleteNotification delegates to repository',
      setUp: () {
        when(() => repository.deleteNotification('n-1'))
            .thenAnswer((_) async => const Result.success(null));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const NotificationDismissed('n-1')),
      verify: (_) {
        verify(() => repository.deleteNotification('n-1')).called(1);
      },
    );

    blocTest<NotificationsBloc, NotificationsState>(
      'clearAllNotifications delegates to repository for current user',
      setUp: () {
        when(() => repository.clearAllNotifications('user-1'))
            .thenAnswer((_) async => const Result.success(null));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const NotificationsClearAllRequested()),
      verify: (_) {
        verify(() => repository.clearAllNotifications('user-1')).called(1);
      },
    );
  });
}
