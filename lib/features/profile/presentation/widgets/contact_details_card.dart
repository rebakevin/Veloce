import 'package:flutter/material.dart';
import 'package:veloce/core/theme/app_colors.dart';

/// The signed-in user's own phone and email (never used for other users).
class ContactDetailsCard extends StatelessWidget {
  const ContactDetailsCard({
    required this.phone,
    required this.email,
    super.key,
  });

  final String phone;
  final String email;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.phone_outlined, color: colors.brand),
            title: Text(phone),
            subtitle: const Text('Phone'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.mail_outline, color: colors.brand),
            title: Text(email),
            subtitle: const Text('Email'),
          ),
        ],
      ),
    );
  }
}
