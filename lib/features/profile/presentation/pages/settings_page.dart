import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:veloce/core/layout/responsive.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/widgets/section_header.dart';

import '../bloc/settings_cubit.dart';

/// `/profile/settings`: theme and notifications, applied immediately.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SettingsCubit>(
      create: (_) => GetIt.instance<SettingsCubit>(),
      child: const SettingsView(),
    );
  }
}

/// The settings screen itself; needs a [SettingsCubit] above it.
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) => ListView(
          padding: Responsive.pagePadding(context)
              .copyWith(top: AppSpacing.lg, bottom: AppSpacing.xl),
          children: [
            const SectionHeader(title: 'Theme'),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('System'),
                  icon: Icon(Icons.phone_android_outlined),
                ),
              ],
              selected: {state.themeMode},
              onSelectionChanged: (selection) => context
                  .read<SettingsCubit>()
                  .selectThemeMode(selection.first),
            ),
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader(title: 'Notifications'),
            Card(
              margin: EdgeInsets.zero,
              child: SwitchListTile(
                title: const Text('Push notifications'),
                subtitle: const Text('Booking updates and reminders'),
                value: state.notificationsEnabled,
                onChanged: (enabled) => context
                    .read<SettingsCubit>()
                    .setNotificationsEnabled(enabled: enabled),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
