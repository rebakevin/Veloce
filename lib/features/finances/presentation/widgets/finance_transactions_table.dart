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
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: colors.line),
          ),
          child: Column(
            children: [
              for (int i = 0; i < displayed.length; i++) ...[
                if (i > 0) Divider(height: 1, color: colors.line),
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
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isEarned ? colors.brandWash : colors.dangerWash,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isEarned ? Icons.arrow_downward : Icons.arrow_upward,
              color: amountColor,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.vehicleName ?? 'Vehicle',
                  style: AppTextStyles.cardTitle.copyWith(
                    color: colors.ink,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${isEarned ? 'Earned' : 'Loss'} • ${Formatters.date(transaction.date)}',
                  style: AppTextStyles.caption.copyWith(color: colors.muted),
                ),
              ],
            ),
          ),
          Text(
            signedAmount,
            style: AppTextStyles.cardTitle.copyWith(
              color: amountColor,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
