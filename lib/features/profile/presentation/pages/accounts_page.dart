import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:veloce/core/layout/responsive.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/app_messenger.dart';
import 'package:veloce/core/widgets/dialog_buttons.dart';
import 'package:veloce/core/widgets/error_view.dart';
import 'package:veloce/core/widgets/loading_view.dart';
import 'package:veloce/core/widgets/page_app_bar.dart';
import 'package:veloce/features/auth/auth.dart';

import '../bloc/accounts_bloc.dart';
import '../widgets/account_sign_in_form.dart';
import '../widgets/account_tile.dart';

/// `/profile/accounts`: the accounts linked to this device. Tapping another
/// account switches to it without a password; when its stored sign-in is gone
/// a sheet asks the user to sign in again.
class AccountsPage extends StatelessWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AccountsBloc>(
      create: (_) =>
          GetIt.instance<AccountsBloc>()..add(const AccountsStarted()),
      child: const AccountsView(),
    );
  }
}

/// The account list; needs an [AccountsBloc] above it.
class AccountsView extends StatelessWidget {
  const AccountsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PageAppBar(title: 'Accounts'),
      body: BlocConsumer<AccountsBloc, AccountsState>(
        listenWhen: (previous, current) =>
            current is AccountsLoaded &&
            current.status != AccountsStatus.idle &&
            current.status != AccountsStatus.working &&
            !(previous is AccountsLoaded && previous.status == current.status),
        listener: _onResult,
        builder: (context, state) => switch (state) {
          AccountsLoading() => const LoadingView(),
          AccountsFailure(:final error) => ErrorView(
            message: error.message,
            onRetry: () =>
                context.read<AccountsBloc>().add(const AccountsStarted()),
          ),
          final AccountsLoaded loaded => _AccountList(state: loaded),
        },
      ),
    );
  }

  void _onResult(BuildContext context, AccountsState state) {
    if (state is! AccountsLoaded) return;
    final bloc = context.read<AccountsBloc>();
    final messenger = GetIt.instance<AppMessenger>();
    final target = state.target;
    switch (state.status) {
      case AccountsStatus.switched:
        bloc.add(const AccountsResultAcknowledged());
        if (target != null) context.go(homeRouteFor(target.role));
      case AccountsStatus.signInRequired:
        if (target != null) _askToSignIn(context, bloc, target);
      case AccountsStatus.removed:
        messenger.success('Removed from this device');
        bloc.add(const AccountsResultAcknowledged());
      case AccountsStatus.added:
        bloc.add(const AccountsResultAcknowledged());
        if (target != null) context.go(homeRouteFor(target.role));
      case AccountsStatus.failed:
        final failure = state.failure;
        if (failure != null) messenger.failure(failure);
        bloc.add(const AccountsResultAcknowledged());
      case AccountsStatus.idle || AccountsStatus.working:
        break;
    }
  }

  Future<void> _askToSignIn(
    BuildContext context,
    AccountsBloc bloc,
    LinkedAccount target,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.lg,
          AppSpacing.gutter,
          MediaQuery.viewInsetsOf(sheetContext).bottom + AppSpacing.xl,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Session expired, sign in again',
                style: AppTextStyles.heading,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Sign in as ${target.name} to switch to this account.',
                style: AppTextStyles.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              AccountSignInForm(
                email: target.email,
                kind: target.authType,
                onSignedIn: (password) {
                  bloc.add(AccountsAddRequested(password: password));
                  Navigator.of(sheetContext).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
    // Dismissed without signing in: leave the "sign in required" state.
    if (!bloc.isClosed) bloc.add(const AccountsResultAcknowledged());
  }
}

class _AccountList extends StatelessWidget {
  const _AccountList({required this.state});

  final AccountsLoaded state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AccountsBloc>();
    return ListView(
      padding: Responsive.pagePadding(context)
          .copyWith(top: AppSpacing.lg, bottom: AppSpacing.xl),
      children: [
        if (state.isWorking) const LinearProgressIndicator(),
        for (final account in state.accounts)
          AccountTile(
            account: account,
            isCurrent: state.isCurrent(account),
            enabled: !state.isWorking,
            onSwitch: () => bloc.add(AccountsSwitchRequested(account.uid)),
            onRemove: () => _confirmRemove(context, bloc, account),
          ),
        const SizedBox(height: AppSpacing.lg),
        OutlinedButton.icon(
          onPressed: state.isWorking
              ? null
              : () => context.push(RouteNames.profileAccountsAdd),
          icon: const Icon(Icons.person_add_alt_outlined),
          label: const Text('Add account'),
        ),
      ],
    );
  }

  static Future<void> _confirmRemove(
    BuildContext context,
    AccountsBloc bloc,
    LinkedAccount account,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove account?'),
        content: Text(
          '${account.name} is removed from this device only. You can add it '
          'again later.',
        ),
        actions: [
          DialogButtons(
            confirmLabel: 'Remove',
            onCancel: () => Navigator.of(context).pop(false),
            onConfirm: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (confirmed == true && !bloc.isClosed) {
      bloc.add(AccountsRemoveRequested(account.uid));
    }
  }
}
