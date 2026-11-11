import 'package:flutter/widgets.dart';

/// The round button left of the tabs that opens a full-screen page.
class ShellAction {
  const ShellAction({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}
