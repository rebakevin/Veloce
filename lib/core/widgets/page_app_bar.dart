import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_back_button.dart';

/// App bar for a screen opened above the tab bar. Shows a back button whenever
/// the router has somewhere to go back to, including inside a `ShellRoute`,
/// where [AppBar]'s own back button stays hidden (the shell has its own
/// navigator) and [Navigator.maybePop] would pop nothing.
class PageAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PageAppBar({required this.title, super.key, this.actions});

  final String title;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    return AppBar(
      automaticallyImplyLeading: false,
      leading: router != null && router.canPop()
          ? AppBackButton(onPressed: router.pop)
          : null,
      title: Text(title),
      actions: actions,
    );
  }
}
