import 'package:equatable/equatable.dart';

import '../enums/auth_provider_kind.dart';

/// Private contact details, readable only by their owner.
class Contact extends Equatable {
  const Contact({
    required this.userId,
    required this.email,
    required this.phone,
    required this.dateOfBirth,
    required this.authProvider,
  });

  final String userId;
  final String email;
  final String phone;
  final DateTime dateOfBirth;
  final AuthProviderKind authProvider;

  Contact copyWith({
    String? userId,
    String? email,
    String? phone,
    DateTime? dateOfBirth,
    AuthProviderKind? authProvider,
  }) {
    return Contact(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      authProvider: authProvider ?? this.authProvider,
    );
  }

  @override
  List<Object?> get props => [userId, email, phone, dateOfBirth, authProvider];
}
