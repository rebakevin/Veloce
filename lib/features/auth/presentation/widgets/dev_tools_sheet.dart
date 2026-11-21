import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/theme/app_spacing.dart';

import '../../domain/dev_account.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/dev_tools_cubit.dart';

/// The debug-only dev panel: switch between the seeded accounts, simulate
/// payment and verification outcomes, and open any route. Opened from the
/// floating button of `DevToolsOverlay`, which provides the [DevToolsCubit].
///
/// Sign-in and sign-out close the panel first: the session change makes the
/// router redirect, which must not run under an open sheet.
class DevToolsSheet extends StatelessWidget {
  const DevToolsSheet({required this.router, super.key});

  final GoRouter router;

  /// Closes the sheet, then runs [action] on the router.
  void _leave(BuildContext context, void Function() action) {
    Navigator.of(context).pop();
    action();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DevToolsCubit>();
    final currentEmail = context.watch<AuthBloc>().state.user?.email;
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        0,
        AppSpacing.gutter,
        AppSpacing.lg,
      ),
      children: [
        Text('Dev tools', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        Text(
          currentEmail == null ? 'Signed out' : 'Signed in as $currentEmail',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        const _SectionLabel('Sign in as'),
        for (final account in DevAccounts.all)
          ListTile(
            dense: true,
            title: Text(account.name),
            subtitle: Text('${account.role.label} · ${account.email}'),
            trailing: account.email == currentEmail
                ? const Icon(Icons.check_circle_outline)
                : null,
            onTap: () {
              Navigator.of(context).pop();
              cubit.signInAs(account);
            },
          ),
        const Divider(),
        const _SectionLabel('Simulate'),
        BlocBuilder<DevToolsCubit, DevToolsState>(
          builder: (context, state) => Column(
            children: [
              SwitchListTile(
                title: const Text('MoMo payments succeed'),
                value: state.momoSucceeds,
                onChanged: (value) => cubit.setMomoSucceeds(value: value),
              ),
              SwitchListTile(
                title: const Text('Verification succeeds'),
                value: state.verificationSucceeds,
                onChanged: (value) =>
                    cubit.setVerificationSucceeds(value: value),
              ),
            ],
          ),
        ),
        const Divider(),
        OutlinedButton(
          onPressed: () =>
              _leave(context, () => router.push(RouteNames.devRoutes)),
          child: const Text('Browse all routes'),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(
          onPressed: () => _leave(context, () => router.go(RouteNames.welcome)),
          child: const Text('Open the real sign-in flow'),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(
          onPressed: () {
            Navigator.of(context).pop();
            cubit.signOut();
          },
          child: const Text('Sign out'),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(text, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}
