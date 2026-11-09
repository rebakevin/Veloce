import 'package:equatable/equatable.dart';

import 'package:veloce/core/domain/enums/user_role.dart';

/// A seeded account for the debug-only `/dev-login` page.
class DevAccount extends Equatable {
  const DevAccount({
    required this.name,
    required this.email,
    required this.role,
  });

  final String name;
  final String email;
  final UserRole role;

  @override
  List<Object?> get props => [name, email, role];
}

/// Accounts created by `tool/seed/seed.js`. Keep both lists in sync.
abstract final class DevAccounts {
  static const String password = 'Veloce#2026';

  static const List<DevAccount> all = [
    DevAccount(
      name: 'Aline Uwase',
      email: 'renter1@veloce.test',
      role: UserRole.renter,
    ),
    DevAccount(
      name: 'Eric Mugisha',
      email: 'renter2@veloce.test',
      role: UserRole.renter,
    ),
    DevAccount(
      name: 'Diane Ingabire',
      email: 'renter3@veloce.test',
      role: UserRole.renter,
    ),
    DevAccount(
      name: 'Patrick Habimana',
      email: 'owner1@veloce.test',
      role: UserRole.owner,
    ),
    DevAccount(
      name: 'Grace Mukamana',
      email: 'owner2@veloce.test',
      role: UserRole.owner,
    ),
    DevAccount(
      name: 'Jean Claude Niyonzima',
      email: 'owner3@veloce.test',
      role: UserRole.owner,
    ),
  ];
}
