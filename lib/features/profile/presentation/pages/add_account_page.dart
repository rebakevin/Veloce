import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:veloce/core/layout/responsive.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/app_messenger.dart';
import 'package:veloce/core/widgets/error_view.dart';
import 'package:veloce/core/widgets/loading_view.dart';
import 'package:veloce/features/auth/auth.dart';

import '../bloc/accounts_bloc.dart';
import '../widgets/account_sign_in_form.dart';

/// `/profile/accounts/add`: sign another account in, link it to this device
/// and continue as that account.
class AddAccountPage extends StatelessWidget {
  const AddAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AccountsBloc>(
      create: (_) =>
          GetIt.instance<AccountsBloc>()..add(const AccountsStarted()),
      child: const AddAccountView(),
    );
  }
}

/// The add-account screen; needs an [AccountsBloc] above it.
class AddAccountView extends StatelessWidget {
  const AddAccountView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add account')),
      body: BlocConsumer<AccountsBloc, AccountsState>(
        listenWhen: (previous, current) =>
            current is AccountsLoaded &&
            (current.status == AccountsStatus.added ||
                current.status == AccountsStatus.failed) &&
            !(previous is AccountsLoaded && previous.status == current.status),
        listener: (context, state) {
          if (state is! AccountsLoaded) return;
          final bloc = context.read<AccountsBloc>();
          if (state.status == AccountsStatus.failed) {
            final failure = state.failure;
            if (failure != null) {
              GetIt.instance<AppMessenger>().failure(failure);
            }
            bloc.add(const AccountsResultAcknowledged());
            return;
          }
          final target = state.target;
          bloc.add(const AccountsResultAcknowledged());
          GetIt.instance<AppMessenger>().success('Account added');
          if (target != null) context.go(homeRouteFor(target.role));
        },
        builder: (context, state) => switch (state) {
          AccountsLoading() => const LoadingView(),
          AccountsFailure(:final error) => ErrorView(
            message: error.message,
            onRetry: () =>
                context.read<AccountsBloc>().add(const AccountsStarted()),
          ),
          final AccountsLoaded loaded => ListView(
            padding: Responsive.pagePadding(context)
                .copyWith(top: AppSpacing.lg, bottom: AppSpacing.xl),
            children: [
              const Text(
                'Sign in to the other account. It is kept on this device so '
                'you can switch back without a password.',
                style: AppTextStyles.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (loaded.isWorking) const LinearProgressIndicator(),
              AccountSignInForm(
                onSignedIn: (password) => context.read<AccountsBloc>().add(
                  AccountsAddRequested(password: password),
                ),
              ),
            ],
          ),
        },
      ),
    );
  }
}
