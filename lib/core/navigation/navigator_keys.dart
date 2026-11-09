import 'package:flutter/widgets.dart';

/// Root navigator. Full-screen routes use it so they open above the tab bar.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);
