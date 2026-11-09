import 'dart:async';
import 'dart:developer';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:veloce/app/app.dart';
import 'package:veloce/app/di/injection_container.dart';
import 'package:veloce/app/router/app_router.dart';
import 'package:veloce/core/config/env.dart';
import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/observability/app_bloc_observer.dart';
import 'package:veloce/firebase_options.dart';

Future<void> main() async {
  await runZonedGuarded(_start, (error, stackTrace) {
    log('Uncaught error', name: 'main', error: error, stackTrace: stackTrace);
  });
}

Future<void> _start() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) => log(
    'Flutter error',
    name: 'main',
    error: details.exception,
    stackTrace: details.stack,
  );
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    log('Platform error', name: 'main', error: error, stackTrace: stackTrace);
    return true;
  };
  Bloc.observer = const AppBlocObserver();

  final Env env;
  try {
    env = Env.fromEnvironment();
  } on StateError catch (error) {
    runApp(ConfigErrorApp(message: error.message));
    return;
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Supabase.initialize(
    url: env.supabaseUrl,
    publishableKey: env.supabaseKey,
    authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
  );
  final preferences = await SharedPreferences.getInstance();

  final getIt = GetIt.instance;
  configureDependencies(
    getIt,
    preferences: preferences,
    supabase: Supabase.instance.client,
  );
  runApp(VeloceApp(router: createAppRouter(getIt<AuthSession>())));
}
