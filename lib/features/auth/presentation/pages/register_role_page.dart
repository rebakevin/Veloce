import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/theme/app_spacing.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/register_bloc.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/role_card.dart';
import '../widgets/step_header.dart';

/// Step 1: renter or owner. Needs the flow's [RegisterBloc] above it.
class RegisterRolePage extends StatelessWidget {
  const RegisterRolePage({super.key});

  void _back(BuildContext context, {required bool isGoogle}) {
    if (isGoogle) {
      // Leaving a half-made Google sign-up signs the account out again.
      context.read<AuthBloc>().add(const SignOutRequested());
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go(RouteNames.welcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGoogle = context.select((RegisterBloc bloc) => bloc.state.isGoogle);
    final bloc = context.read<RegisterBloc>();
    return PopScope(
      canPop: !isGoogle && context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back(context, isGoogle: isGoogle);
      },
      child: AuthScaffold(
        title: 'Create account',
        onBack: () => _back(context, isGoogle: isGoogle),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StepHeader(
              step: 1,
              total: isGoogle ? 2 : 4,
              title: 'How will you use Veloce?',
              subtitle: 'Pick one. You cannot change it later.',
            ),
            RoleCard(
              icon: Icons.key_outlined,
              title: UserRole.renter.label,
              description: 'I want to rent a car for a few days.',
              onTap: () =>
                  bloc.add(const RegisterRoleSelected(UserRole.renter)),
            ),
            const SizedBox(height: AppSpacing.md),
            RoleCard(
              icon: Icons.directions_car_outlined,
              title: UserRole.owner.label,
              description: 'I want to earn by renting out my car.',
              onTap: () => bloc.add(const RegisterRoleSelected(UserRole.owner)),
            ),
            if (isGoogle) ...[
              const SizedBox(height: AppSpacing.xl),
              TextButton(
                onPressed: () => _back(context, isGoogle: true),
                child: const Text('Use a different account'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
