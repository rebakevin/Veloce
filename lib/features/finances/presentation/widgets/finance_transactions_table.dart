import 'package:flutter/material.dart';
import 'package:veloce/core/formatting/formatters.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';

import '../../domain/entities/finance_transaction.dart';

/// Table / list displaying finance transactions (Earned or Loss) newest first.
class FinanceTransactionsTable extends StatelessWidget {
  const FinanceTransactionsTable({
    required this.transactions,
    this.previewLimit,
    this.onViewAll,
    super.key,
  });

  final List<FinanceTransaction> transactions;
  final int? previewLimit;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        alignment: Alignment.center,
        child: Text(
          'No transactions in this period.',
          style: AppTextStyles.body.copyWith(color: colors.muted),
        ),
      );
    }

    final hasMore = previewLimit != null && transactions.length > previewLimit!;
    final displayed = hasMore
        ? transactions.take(previewLimit!).toList()
        : transactions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Column(
            children: [
              const _HeaderRow(),
              for (int i = 0; i < displayed.length; i++) ...[
                Divider(height: 1, color: colors.sand),
                _TransactionRow(transaction: displayed[i]),
              ],
            ],
          ),
        ),
        if (hasMore && onViewAll != null) ...[
          const SizedBox(height: AppSpacing.md),
          Center(
            child: TextButton(
              onPressed: onViewAll,
              child: Text(
                'View all transactions (${transactions.length})',
                style: AppTextStyles.button.copyWith(color: colors.brand),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction});

  final FinanceTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isEarned = transaction.type == FinanceEntryType.earned;
    final signedAmount = isEarned
        ? '+ ${Formatters.rwf(transaction.amount)}'
        : '- ${Formatters.rwf(transaction.amount)}';

    final amountColor = isEarned ? colors.brand : colors.danger;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 14,
            child: Text(
              transaction.vehicleName ?? 'Vehicle',
              style: AppTextStyles.bodySmall.copyWith(
                color: colors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 11,
            child: Text(
              signedAmount,
              textAlign: TextAlign.end,
              style: AppTextStyles.bodySmall.copyWith(
                color: amountColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            flex: 10,
            child: Text(
              Formatters.date(transaction.date),
              textAlign: TextAlign.end,
              style: AppTextStyles.bodySmall.copyWith(color: colors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.label.copyWith(color: context.colors.muted);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(flex: 14, child: Text('Car', style: style)),
          Expanded(
            flex: 11,
            child: Text('Amount', textAlign: TextAlign.end, style: style),
          ),
          Expanded(
            flex: 10,
            child: Text('Date', textAlign: TextAlign.end, style: style),
          ),
        ],
      ),
    );
  }
}
