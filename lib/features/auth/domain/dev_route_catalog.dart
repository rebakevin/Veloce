import 'package:equatable/equatable.dart';

import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/navigation/auth_redirect.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/navigation/seed_ids.dart';

/// One screen the `/dev-routes` page can open.
class DevRouteEntry extends Equatable {
  const DevRouteEntry({required this.pattern, required this.path, this.role});

  /// The registered path, for example `/booking/:id/pay`.
  final String pattern;

  /// [pattern] with its parameters filled with seeded ids.
  final String path;

  /// The role the router lets through, or null when any signed-in user can open it.
  final UserRole? role;

  @override
  List<Object?> get props => [pattern, path, role];
}

/// Turns the router's registered paths into links that open on the seeded data.
abstract final class DevRouteCatalog {
  static final RegExp _param = RegExp(r':\w+');

  static List<DevRouteEntry> fromPatterns(Iterable<String> patterns) {
    final unique = patterns.toSet().where(
      (pattern) => !RouteNames.isDevTool(pattern),
    );
    final sorted = unique.toList()..sort();
    return [
      for (final pattern in sorted)
        DevRouteEntry(
          pattern: pattern,
          path: _fill(pattern),
          role: requiredRoleFor(pattern),
        ),
    ];
  }

  static String _fill(String pattern) {
    final id = _sampleIdFor(pattern);
    return pattern.replaceAllMapped(_param, (_) => id);
  }

  static String _sampleIdFor(String pattern) {
    if (pattern.startsWith('/booking')) return SeedIds.booking;
    if (pattern.startsWith('/user')) return SeedIds.renter;
    return SeedIds.car;
  }
}
