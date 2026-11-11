import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:veloce/core/theme/app_theme.dart';
import 'package:veloce/core/theme/theme_cubit.dart';
import 'package:veloce/core/widgets/app_messenger.dart';
import 'package:veloce/features/auth/auth.dart';

/// Root widget: theme, messenger and router. Blocs that outlive a route (theme,
/// later auth) are provided here; screen blocs live at their route.
class VeloceApp extends StatelessWidget {
  const VeloceApp({required this.router, super.key});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    final getIt = GetIt.instance;
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<ThemeCubit>()),
        BlocProvider.value(value: getIt<AuthBloc>()..add(const AuthStarted())),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) => MaterialApp.router(
          title: 'Veloce',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          scaffoldMessengerKey: getIt<AppMessenger>().key,
          routerConfig: router,
        ),
      ),
    );
  }
}

/// Shown instead of the app when startup configuration is missing.
class ConfigErrorApp extends StatelessWidget {
  const ConfigErrorApp({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(message, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}
