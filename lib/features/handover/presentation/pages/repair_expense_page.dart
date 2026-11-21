import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:veloce/core/data/services/booking_lookup.dart';
import 'package:veloce/core/domain/entities/booking.dart';
import 'package:veloce/core/domain/entities/repair_expense.dart';
import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/handover/domain/repositories/repair_expense_repository.dart';

import '../bloc/repair_expense_cubit.dart';
import '../bloc/repair_expense_state.dart';

class RepairExpensePage extends StatelessWidget {
  const RepairExpensePage({required this.bookingId, super.key});

  final String bookingId;

  @override
  Widget build(BuildContext context) {
    final userId = GetIt.I<AuthSession>().currentUserId;

    return Scaffold(
      appBar: AppBar(title: const Text('Repair expenses')),
      body: StreamBuilder<Result<Booking>>(
        stream: GetIt.I<BookingLookup>().watch(bookingId),
        builder: (context, bookingSnapshot) {
          if (bookingSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!bookingSnapshot.hasData) {
            return const Center(child: Text('Unable to load booking.'));
          }

          return bookingSnapshot.data!.when(
            success: (booking) {
              if (booking.ownerId != userId || userId == null) {
                return const Center(
                  child: Text('Only the vehicle owner can manage expenses.'),
                );
              }

              return BlocProvider(
                create: (_) => RepairExpenseCubit(
                  bookingId: bookingId,
                  vehicleId: booking.vehicleId,
                  ownerId: userId,
                  repository: GetIt.I<RepairExpenseRepository>(),
                ),
                child: const _ExpenseContent(),
              );
            },
            failure: (failure) {
              return Center(child: Text(failure.message));
            },
          );
        },
      ),
    );
  }
}

class _ExpenseContent extends StatelessWidget {
  const _ExpenseContent();

  Future<void> _confirmDelete(
    BuildContext context,
    RepairExpense expense,
  ) async {
    final cubit = context.read<RepairExpenseCubit>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete expense?'),
        content: const Text(
          'This will permanently delete this repair expense.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) await cubit.delete(expense);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RepairExpenseCubit, RepairExpenseState>(
      listenWhen: (previous, current) =>
          current.notice != null && previous.notice != current.notice,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(state.notice!)));
      },
      builder: (context, state) {
        if (state.loadStatus == RepairExpenseLoad.failed) {
          return const Center(child: Text('Unable to load repair expenses.'));
        }

        if (state.loadStatus == RepairExpenseLoad.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        final expenses = state.expenses;

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Manage repair expenses',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Total repair expenses: ${state.total} RWF'),
            const SizedBox(height: 24),
            const _ExpenseForm(),
            const Divider(height: 36),
            const Text(
              'Saved expenses',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (expenses.isEmpty)
              const Text('No repair expenses have been added.')
            else
              ...expenses.map((expense) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${expense.amount} RWF',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(expense.description),
                        if (expense.receiptUrl != null &&
                            expense.receiptUrl!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              expense.receiptUrl!,
                              height: 140,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Text('Receipt image unavailable.');
                              },
                            ),
                          ),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              tooltip: 'Edit expense',
                              onPressed: () => context
                                  .read<RepairExpenseCubit>()
                                  .startEditing(expense),
                              icon: const Icon(Icons.edit),
                            ),
                            IconButton(
                              tooltip: 'Delete expense',
                              onPressed: () => _confirmDelete(context, expense),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}

/// Owns the text controllers only. All other form state lives in the cubit,
/// and a [BlocListener] copies the edited expense into the controllers.
class _ExpenseForm extends StatefulWidget {
  const _ExpenseForm();

  @override
  State<_ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<_ExpenseForm> {
  final _amount = TextEditingController();
  final _description = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickReceipt(RepairExpenseCubit cubit) async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image == null) return;

    final bytes = await image.readAsBytes();
    if (cubit.isClosed) return;

    cubit.receiptPicked(name: image.name, bytes: bytes);
  }

  void _syncControllers(RepairExpenseState state) {
    final editing = state.editing;
    _amount.text = editing?.amount.toString() ?? '';
    _description.text = editing?.description ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RepairExpenseCubit>();

    return BlocConsumer<RepairExpenseCubit, RepairExpenseState>(
      listenWhen: (previous, current) =>
          previous.editing != current.editing ||
          (previous.isSaving &&
              !current.isSaving &&
              current.errorMessage == null),
      listener: (context, state) => _syncControllers(state),
      builder: (context, state) {
        final isEditing = state.editing != null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing ? 'Edit repair expense' : 'Add repair expense',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (RWF)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: state.isSaving ? null : () => _pickReceipt(cubit),
              icon: const Icon(Icons.photo_camera),
              label: Text(
                state.hasNewReceipt
                    ? 'Receipt selected'
                    : state.existingReceiptUrl != null
                    ? 'Replace receipt photo'
                    : 'Add receipt photo',
              ),
            ),
            if (state.hasNewReceipt) ...[
              const SizedBox(height: 8),
              Text(state.receiptName ?? ''),
            ] else if (state.existingReceiptUrl != null) ...[
              const SizedBox(height: 8),
              const Text('Existing receipt photo is attached.'),
            ],
            if (state.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                state.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: state.isSaving
                    ? null
                    : () => cubit.save(
                        amountText: _amount.text,
                        description: _description.text,
                      ),
                child: state.isSaving
                    ? const CircularProgressIndicator()
                    : Text(isEditing ? 'Update expense' : 'Save expense'),
              ),
            ),
            if (isEditing)
              TextButton(
                onPressed: state.isSaving ? null : cubit.clearForm,
                child: const Text('Cancel editing'),
              ),
          ],
        );
      },
    );
  }
}
