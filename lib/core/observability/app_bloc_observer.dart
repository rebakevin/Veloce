import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Logs state changes in debug builds and errors in every build.
class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    if (kDebugMode) {
      log(
        '${change.currentState} -> ${change.nextState}',
        name: '${bloc.runtimeType}',
      );
    }
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    log(
      'Unhandled bloc error',
      name: '${bloc.runtimeType}',
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
    super.onError(bloc, error, stackTrace);
  }
}
