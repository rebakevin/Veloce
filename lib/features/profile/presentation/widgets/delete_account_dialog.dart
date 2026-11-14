import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/widgets/dialog_buttons.dart';

import '../bloc/delete_account_cubit.dart';

/// Opens the delete-account confirmation. Email accounts must type their
/// password ([needsPassword]); Google accounts confirm in the Google chooser.
Future<void> showDeleteAccountDialog(
  BuildContext context, {
  required bool needsPassword,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => BlocProvider<DeleteAccountCubit>(
      create: (_) => GetIt.instance<DeleteAccountCubit>(),
      child: DeleteAccountDialog(needsPassword: needsPassword),
    ),
  );
}

/// The dialog itself; needs a [DeleteAccountCubit] above it.
class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({required this.needsPassword, super.key});

  final bool needsPassword;

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final TextEditingController _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DeleteAccountCubit, DeleteAccountState>(
      listener: (context, state) {
        if (state is DeleteAccountDone) Navigator.of(context).pop();
      },
      builder: (context, state) {
        final running = state is DeleteAccountRunning;
        return AlertDialog(
          title: const Text('Delete your account?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This permanently deletes your profile, cars, bookings, '
                'payments and reviews, both given and received. It cannot be '
                'undone.',
              ),
              if (widget.needsPassword) ...[
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: _password,
                  obscureText: true,
                  enabled: !running,
                  decoration: const InputDecoration(labelText: 'Your password'),
                ),
              ],
              if (state case DeleteAccountFailure(:final error)) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  error.message,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              if (running) ...[
                const SizedBox(height: AppSpacing.lg),
                const LinearProgressIndicator(),
              ],
            ],
          ),
          actions: [
            DialogButtons(
              confirmLabel: 'Delete account',
              destructive: true,
              onCancel: running ? null : () => Navigator.of(context).pop(),
              onConfirm: running
                  ? null
                  : () => context.read<DeleteAccountCubit>().delete(
                      password: widget.needsPassword ? _password.text : null,
                    ),
            ),
          ],
        );
      },
    );
  }
}
