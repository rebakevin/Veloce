import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:veloce/app/router/main_bar.dart';
import 'package:veloce/app/router/shell_action.dart';
import 'package:veloce/app/router/shell_destination.dart';
import 'package:veloce/features/notifications/notifications.dart';

/// Bottom bar shared by the renter and owner shells, as in the mock: a side
/// action, three tabs and the notifications bell.
class RoleShell extends StatelessWidget {
  const RoleShell({
    required this.navigationShell,
    required this.destinations,
    required this.sideAction,
    required this.notificationsRoute,
    super.key,
  });

  final StatefulNavigationShell navigationShell;
  final List<ShellDestination> destinations;
  final ShellAction sideAction;
  final String notificationsRoute;

  @override
  Widget build(BuildContext context) {
    Widget buildMainBar({int unreadCount = 0}) {
      return MainBar(
        destinations: destinations,
        selectedIndex: navigationShell.currentIndex,
        onSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        sideAction: sideAction,
        onSide: () => context.push(sideAction.route),
        onNotifications: () => context.push(notificationsRoute),
        unreadNotificationsCount: unreadCount,
      );
    }

    final hasNotificationsBloc = GetIt.instance
        .isRegistered<NotificationsBloc>();

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: hasNotificationsBloc
          ? BlocBuilder<NotificationsBloc, NotificationsState>(
              bloc: GetIt.instance<NotificationsBloc>(),
              builder: (context, state) {
                final unreadCount = switch (state) {
                  NotificationsLoaded(
                    :final unreadCount,
                    :final notificationsEnabled,
                  ) =>
                    notificationsEnabled ? unreadCount : 0,
                  _ => 0,
                };

                return buildMainBar(unreadCount: unreadCount);
              },
            )
          : buildMainBar(unreadCount: 0),
    );
  }
}
