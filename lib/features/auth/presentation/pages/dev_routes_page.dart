import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:veloce/core/theme/app_spacing.dart';

import '../../domain/dev_route_catalog.dart';

/// Debug-only list of every screen in the app, so a placeholder can be opened
/// without typing its path. Reads the live router, so a new route shows up here
/// without editing this page. Registered only when `kDebugMode`.
class DevRoutesPage extends StatelessWidget {
  const DevRoutesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final routes = GoRouter.of(context).configuration.routes;
    final entries = DevRouteCatalog.fromPatterns(patterns(routes));
    return Scaffold(
      appBar: AppBar(title: Text('All routes (${entries.length})')),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        itemCount: entries.length,
        itemBuilder: (context, index) => _RouteTile(entry: entries[index]),
      ),
    );
  }

  /// Every registered path, with nested routes joined to their parent.
  static List<String> patterns(List<RouteBase> routes, [String parent = '']) {
    final result = <String>[];
    for (final route in routes) {
      if (route is GoRoute) {
        final full = route.path.startsWith('/')
            ? route.path
            : '$parent/${route.path}';
        result
          ..add(full)
          ..addAll(patterns(route.routes, full));
      } else {
        result.addAll(patterns(route.routes, parent));
      }
    }
    return result;
  }
}

class _RouteTile extends StatelessWidget {
  const _RouteTile({required this.entry});

  final DevRouteEntry entry;

  @override
  Widget build(BuildContext context) {
    final role = entry.role;
    return ListTile(
      minTileHeight: AppSizes.iconControl,
      title: Text(entry.pattern),
      subtitle: role == null ? null : Text('${role.label} only'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push(entry.path),
    );
  }
}
