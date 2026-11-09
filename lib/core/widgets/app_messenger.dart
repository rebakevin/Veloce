import 'package:flutter/material.dart';

import '../error/app_failure.dart';
import '../theme/app_colors.dart';

/// Global SnackBars. Blocs never show them; a `BlocListener` calls this.
class AppMessenger {
  final GlobalKey<ScaffoldMessengerState> key =
      GlobalKey<ScaffoldMessengerState>();

  void success(String message) => _show(message, isError: false);

  void error(String message) => _show(message, isError: true);

  /// Shows the plain-English text of a failure, never raw exception text.
  void failure(AppFailure failure) => error(failure.message);

  void _show(String message, {required bool isError}) {
    final messenger = key.currentState;
    if (messenger == null) return;
    final colors = Theme.of(key.currentContext ?? messenger.context)
        .extension<AppColors>();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? colors?.danger : colors?.brandDeep,
          duration: Duration(seconds: isError ? 5 : 3),
        ),
      );
  }
}
