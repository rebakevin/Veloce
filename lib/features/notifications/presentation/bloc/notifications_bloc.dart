import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:veloce/core/data/services/preferences_service.dart';
import 'package:veloce/core/domain/entities/app_notification.dart';
import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/error/app_failure.dart';

import '../../domain/repositories/notifications_repository.dart';

sealed class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => [];
}

final class NotificationsStarted extends NotificationsEvent {
  const NotificationsStarted();
}

final class NotificationsUpdated extends NotificationsEvent {
  const NotificationsUpdated({
    required this.notifications,
    required this.notificationsEnabled,
  });

  final List<AppNotification> notifications;
  final bool notificationsEnabled;

  @override
  List<Object?> get props => [notifications, notificationsEnabled];
}

final class NotificationMarkReadRequested extends NotificationsEvent {
  const NotificationMarkReadRequested(this.notificationId);

  final String notificationId;

  @override
  List<Object?> get props => [notificationId];
}

final class NotificationMarkAllReadRequested extends NotificationsEvent {
  const NotificationMarkAllReadRequested();
}

final class NotificationDismissed extends NotificationsEvent {
  const NotificationDismissed(this.notificationId);

  final String notificationId;

  @override
  List<Object?> get props => [notificationId];
}

final class NotificationsClearAllRequested extends NotificationsEvent {
  const NotificationsClearAllRequested();
}

final class NotificationsFailed extends NotificationsEvent {
  const NotificationsFailed(this.failure);

  final AppFailure failure;

  @override
  List<Object?> get props => [failure];
}

sealed class NotificationsState extends Equatable {
  const NotificationsState();

  @override
  List<Object?> get props => [];
}

final class NotificationsInitial extends NotificationsState {
  const NotificationsInitial();
}

final class NotificationsLoading extends NotificationsState {
  const NotificationsLoading();
}

final class NotificationsLoaded extends NotificationsState {
  const NotificationsLoaded({
    required this.notifications,
    required this.unreadCount,
    required this.notificationsEnabled,
  });

  final List<AppNotification> notifications;
  final int unreadCount;
  final bool notificationsEnabled;

  @override
  List<Object?> get props => [notifications, unreadCount, notificationsEnabled];
}

final class NotificationsEmpty extends NotificationsState {
  const NotificationsEmpty({this.notificationsEnabled = true});

  final bool notificationsEnabled;

  @override
  List<Object?> get props => [notificationsEnabled];
}

final class NotificationsFailure extends NotificationsState {
  const NotificationsFailure(this.failure);

  final AppFailure failure;

  @override
  List<Object?> get props => [failure];
}

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  NotificationsBloc({
    required NotificationsRepository repository,
    required AuthSession session,
    required PreferencesService preferences,
  }) : _repository = repository,
       _session = session,
       _preferences = preferences,
       super(const NotificationsInitial()) {
    on<NotificationsStarted>(_onStarted);
    on<NotificationsUpdated>(_onUpdated);
    on<NotificationsFailed>(_onFailed);
    on<NotificationMarkReadRequested>(_onMarkReadRequested);
    on<NotificationMarkAllReadRequested>(_onMarkAllReadRequested);
    on<NotificationDismissed>(_onDismissed);
    on<NotificationsClearAllRequested>(_onClearAllRequested);
  }

  final NotificationsRepository _repository;
  final AuthSession _session;
  final PreferencesService _preferences;

  StreamSubscription<List<AppNotification>>? _notificationsSubscription;
  StreamSubscription<void>? _sessionSubscription;
  StreamSubscription<bool>? _prefSubscription;

  Future<void> _onStarted(
    NotificationsStarted event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(const NotificationsLoading());

    await _sessionSubscription?.cancel();
    _sessionSubscription = _session.changes.listen((_) {
      _bindNotificationsStream();
    });

    await _prefSubscription?.cancel();
    _prefSubscription = _preferences.notificationsEnabledChanges.listen((
      enabled,
    ) {
      _bindNotificationsStream();
    });

    _bindNotificationsStream();
  }

  void _bindNotificationsStream() {
    _notificationsSubscription?.cancel();

    final userId = _session.currentUserId;
    if (userId == null) {
      add(
        NotificationsUpdated(
          notifications: const [],
          notificationsEnabled: _preferences.notificationsEnabled,
        ),
      );
      return;
    }

    _notificationsSubscription = _repository
        .watchNotifications(userId)
        .listen(
          (notifications) {
            add(
              NotificationsUpdated(
                notifications: notifications,
                notificationsEnabled: _preferences.notificationsEnabled,
              ),
            );
          },
          onError: (Object error) {
            add(NotificationsFailed(UnknownFailure(error.toString())));
          },
        );
  }

  void _onFailed(NotificationsFailed event, Emitter<NotificationsState> emit) {
    emit(NotificationsFailure(event.failure));
  }

  void _onUpdated(
    NotificationsUpdated event,
    Emitter<NotificationsState> emit,
  ) {
    if (!event.notificationsEnabled) {
      emit(
        const NotificationsLoaded(
          notifications: [],
          unreadCount: 0,
          notificationsEnabled: false,
        ),
      );
      return;
    }

    if (event.notifications.isEmpty) {
      emit(const NotificationsEmpty(notificationsEnabled: true));
      return;
    }

    final unreadCount = event.notifications.where((n) => !n.read).length;

    emit(
      NotificationsLoaded(
        notifications: event.notifications,
        unreadCount: unreadCount,
        notificationsEnabled: true,
      ),
    );
  }

  Future<void> _onMarkReadRequested(
    NotificationMarkReadRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    await _repository.markAsRead(event.notificationId);
  }

  Future<void> _onMarkAllReadRequested(
    NotificationMarkAllReadRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    final userId = _session.currentUserId;
    if (userId == null) return;
    await _repository.markAllAsRead(userId);
  }

  Future<void> _onDismissed(
    NotificationDismissed event,
    Emitter<NotificationsState> emit,
  ) async {
    await _repository.deleteNotification(event.notificationId);
  }

  Future<void> _onClearAllRequested(
    NotificationsClearAllRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    final userId = _session.currentUserId;
    if (userId == null) return;
    await _repository.clearAllNotifications(userId);
  }

  @override
  Future<void> close() async {
    await _notificationsSubscription?.cancel();
    await _sessionSubscription?.cancel();
    await _prefSubscription?.cancel();
    return super.close();
  }
}
