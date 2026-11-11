import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:veloce/core/constants/app_constants.dart';
import 'package:veloce/core/layout/responsive.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/app_messenger.dart';

import '../widgets/mail_launcher.dart';

/// `/profile/contact`: the support email; tapping it opens the mail app.
class ContactPage extends StatelessWidget {
  const ContactPage({super.key, this.launcher = const UrlMailLauncher()});

  final MailLauncher launcher;

  Future<void> _write() async {
    final opened = await launcher.compose(
      to: AppConstants.supportEmail,
      subject: 'Veloce support',
    );
    if (!opened) {
      GetIt.instance<AppMessenger>().error(
        'No email app found. Write to ${AppConstants.supportEmail} instead.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact')),
      body: ListView(
        padding: Responsive.pagePadding(context)
            .copyWith(top: AppSpacing.xl, bottom: AppSpacing.xl),
        children: [
          const Text(
            'Need help with a booking, a payment or your account? Write to us '
            'and we will answer as soon as we can.',
            style: AppTextStyles.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              minTileHeight: AppSizes.iconControl,
              leading: Icon(Icons.mail_outline, color: context.colors.brand),
              title: const Text(AppConstants.supportEmail),
              subtitle: const Text('Tap to write an email'),
              onTap: _write,
            ),
          ),
        ],
      ),
    );
  }
}
