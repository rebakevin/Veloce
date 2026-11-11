import 'package:url_launcher/url_launcher.dart';

/// Opens the device's mail app. A seam so the contact screen can be tested.
abstract interface class MailLauncher {
  /// `false` when no mail app could be opened.
  Future<bool> compose({required String to, required String subject});
}

class UrlMailLauncher implements MailLauncher {
  const UrlMailLauncher();

  @override
  Future<bool> compose({required String to, required String subject}) async {
    final uri = Uri(
      scheme: 'mailto',
      path: to,
      queryParameters: {'subject': subject},
    );
    try {
      return await launchUrl(uri);
    } on Object {
      return false;
    }
  }
}
