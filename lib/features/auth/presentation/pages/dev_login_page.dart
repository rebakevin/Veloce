import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:veloce/core/data/services/momo_gateway_sim.dart';
import 'package:veloce/core/data/services/verification_sim.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/widgets/app_messenger.dart';

import '../../data/dev_sign_in.dart';
import '../../domain/dev_account.dart';
import '../bloc/dev_login_cubit.dart';

/// Debug-only quick login for the seeded accounts. Registered only when
/// `kDebugMode`, so it cannot exist in a release build.
class DevLoginPage extends StatelessWidget {
  const DevLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final getIt = GetIt.instance;
    return BlocProvider(
      create: (_) => DevLoginCubit(
        signIn: getIt<DevSignIn>(),
        momo: getIt<MomoGatewaySim>(),
        verification: getIt<VerificationSim>(),
      ),
      child: BlocListener<DevLoginCubit, DevLoginState>(
        listener: _onState,
        child: const _DevLoginView(),
      ),
    );
  }

  void _onState(BuildContext context, DevLoginState state) {
    switch (state.status) {
      case DevLoginStatus.signedIn:
        // The router redirect moves a signed-in user from the splash to Home.
        context.go(RouteNames.splash);
      case DevLoginStatus.failed:
        GetIt.instance<AppMessenger>().error(
          state.message ?? 'Sign-in failed.',
        );
      case DevLoginStatus.idle || DevLoginStatus.signingIn:
        break;
    }
  }
}

class _DevLoginView extends StatelessWidget {
  const _DevLoginView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DevLoginCubit>();
    return Scaffold(
      appBar: AppBar(title: const Text('Dev login')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        children: [
          for (final account in DevAccounts.all)
            ListTile(
              minTileHeight: AppSizes.listRow,
              title: Text(account.name),
              subtitle: Text('${account.role.label} · ${account.email}'),
              onTap: () => cubit.signInAs(account),
            ),
          const Divider(),
          BlocBuilder<DevLoginCubit, DevLoginState>(
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
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton(
            onPressed: cubit.signOut,
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}
