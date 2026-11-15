import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:veloce/core/domain/entities/app_notification.dart';
import 'package:veloce/core/domain/enums/notification_type.dart';
import 'package:veloce/core/theme/app_theme.dart';
import 'package:veloce/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:veloce/features/notifications/presentation/pages/notifications_page.dart';

class _MockNotificationsBloc
    extends MockBloc<NotificationsEvent, NotificationsState>
    implements NotificationsBloc {}

void main() {
  late _MockNotificationsBloc bloc;

  final testDate = DateTime.now().subtract(const Duration(hours: 2));
  final notif = AppNotification(
    id: 'n-1',
    userId: 'user-1',
    type: NotificationType.requestReceived,
    title: 'New booking request',
    text: 'A renter wants to rent your car.',
    bookingId: 'booking-1',
    read: false,
    createdAt: testDate,
  );

  setUp(() {
    bloc = _MockNotificationsBloc();
  });

  Widget buildWidget() {
    return MaterialApp(
      theme: AppTheme.light,
      home: BlocProvider<NotificationsBloc>.value(
        value: bloc,
        child: const NotificationsPage(),
      ),
    );
  }

  testWidgets('shows empty state when there are no notifications', (
    tester,
  ) async {
    when(() => bloc.state)
        .thenReturn(const NotificationsEmpty(notificationsEnabled: true));

    await tester.pumpWidget(buildWidget());
    await tester.pump();

    expect(find.text('No notifications'), findsOneWidget);
    expect(find.text('You have no notifications right now.'), findsOneWidget);
  });

  testWidgets(
    'shows notification items and Mark all read button when unread notifications exist',
    (tester) async {
      when(() => bloc.state).thenReturn(
        NotificationsLoaded(
          notifications: [notif],
          unreadCount: 1,
          notificationsEnabled: true,
        ),
      );

      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.text('New booking request'), findsOneWidget);
      expect(find.text('A renter wants to rent your car.'), findsOneWidget);
      expect(find.text('Mark all read'), findsOneWidget);
    },
  );

  testWidgets(
    'shows disabled message when notifications are turned off in settings',
    (tester) async {
      when(() => bloc.state).thenReturn(
        const NotificationsLoaded(
          notifications: [],
          unreadCount: 0,
          notificationsEnabled: false,
        ),
      );

      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.text('Notifications turned off'), findsOneWidget);
      expect(find.text('Open Settings'), findsOneWidget);
    },
  );
}
