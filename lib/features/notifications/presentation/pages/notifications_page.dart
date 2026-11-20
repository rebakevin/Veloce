import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:veloce/core/layout/responsive.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/empty_state.dart';
import 'package:veloce/core/widgets/error_view.dart';
import 'package:veloce/core/widgets/loading_view.dart';
import 'package:veloce/core/widgets/page_app_bar.dart';
import 'package:veloce/core/widgets/primary_button.dart';

import '../bloc/notifications_bloc.dart';
import '../widgets/notification_tile.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    NotificationsBloc? bloc;
    try {
      bloc = context.read<NotificationsBloc>();
    } catch (_) {
      if (GetIt.instance.isRegistered<NotificationsBloc>()) {
        bloc = GetIt.instance<NotificationsBloc>();
      }
    }

    if (bloc == null) {
      return const Scaffold(
        appBar: PageAppBar(title: 'Notifications'),
        body: SizedBox.shrink(),
      );
    }

    return BlocProvider.value(value: bloc, child: const _NotificationsView());
  }
}

class _NotificationsView extends StatelessWidget {
  const _NotificationsView();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return BlocBuilder<NotificationsBloc, NotificationsState>(
      builder: (context, state) {
        final unreadCount = switch (state) {
          NotificationsLoaded(
            :final unreadCount,
            :final notificationsEnabled,
          ) =>
            notificationsEnabled ? unreadCount : 0,
          _ => 0,
        };

        final hasItems = switch (state) {
          NotificationsLoaded(
            :final notifications,
            :final notificationsEnabled,
          ) =>
            notificationsEnabled && notifications.isNotEmpty,
          _ => false,
        };

        return Scaffold(
          appBar: PageAppBar(
            title: 'Notifications',
            actions: [
              if (unreadCount > 0)
                TextButton(
                  onPressed: () => context.read<NotificationsBloc>().add(
                    const NotificationMarkAllReadRequested(),
                  ),
                  child: Text(
                    'Mark all read',
                    style: AppTextStyles.label.copyWith(color: colors.brand),
                  ),
                ),
              if (hasItems)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: colors.ink),
                  onSelected: (value) {
                    if (value == 'clear_all') {
                      context.read<NotificationsBloc>().add(
                        const NotificationsClearAllRequested(),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'clear_all',
                      child: Text('Clear all notifications'),
                    ),
                  ],
                ),
            ],
          ),
          body: switch (state) {
            NotificationsInitial() ||
            NotificationsLoading() => const LoadingView(),
            NotificationsFailure(:final failure) => ErrorView(
              message: failure.message,
              onRetry: () => context.read<NotificationsBloc>().add(
                const NotificationsStarted(),
              ),
            ),
            NotificationsEmpty(:final notificationsEnabled)
                when !notificationsEnabled =>
              _buildDisabledView(context),
            NotificationsEmpty() => const EmptyState(
              icon: Icons.notifications_none_outlined,
              title: 'No notifications',
              message: 'You have no notifications right now.',
            ),
            NotificationsLoaded(
              :final notifications,
              :final notificationsEnabled,
            ) =>
              !notificationsEnabled
                  ? _buildDisabledView(context)
                  : notifications.isEmpty
                  ? const EmptyState(
                      icon: Icons.notifications_none_outlined,
                      title: 'No notifications',
                      message: 'You have no notifications right now.',
                    )
                  : ListView.separated(
                      padding: Responsive.pagePadding(context)
                          .copyWith(top: AppSpacing.md, bottom: AppSpacing.xl),
                      itemCount: notifications.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final item = notifications[index];
                        return NotificationTile(
                          notification: item,
                          onTap: () {
                            if (!item.read) {
                              context.read<NotificationsBloc>().add(
                                NotificationMarkReadRequested(item.id),
                              );
                            }
                            if (item.bookingId != null) {
                              context.push(RouteNames.booking(item.bookingId!));
                            }
                          },
                          onDismiss: () {
                            context.read<NotificationsBloc>().add(
                              NotificationDismissed(item.id),
                            );
                          },
                        );
                      },
                    ),
          },
        );
      },
    );
  }

  Widget _buildDisabledView(BuildContext context) {
    return Center(
      child: Padding(
        padding: Responsive.pagePadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const EmptyState(
              icon: Icons.notifications_off_outlined,
              title: 'Notifications turned off',
              message: 'Turn on notifications in Settings to stay updated about your rentals and bookings.',
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'Open Settings',
              onPressed: () => context.push(RouteNames.profileSettings),
            ),
          ],
        ),
      ),
    );
  }
}
