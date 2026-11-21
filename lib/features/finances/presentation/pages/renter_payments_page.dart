import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:veloce/core/domain/enums/transaction_status.dart';
import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/formatting/formatters.dart';
import 'package:veloce/core/layout/responsive.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/empty_state.dart';
import 'package:veloce/core/widgets/error_view.dart';
import 'package:veloce/core/widgets/loading_view.dart';
import 'package:veloce/core/widgets/page_app_bar.dart';
import 'package:veloce/core/widgets/status_chip.dart';

import '../../domain/entities/renter_payment_item.dart';
import '../../domain/enums/renter_payment_kind.dart';
import '../../domain/repositories/finances_repository.dart';
import '../bloc/renter_payments_cubit.dart';

class RenterPaymentsPage extends StatelessWidget {
  const RenterPaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (!GetIt.instance.isRegistered<FinancesRepository>() ||
        !GetIt.instance.isRegistered<AuthSession>()) {
      return const Scaffold(
        appBar: PageAppBar(title: 'Payments'),
        body: SizedBox.shrink(),
      );
    }
    return BlocProvider(
      create: (_) => RenterPaymentsCubit(
        repository: GetIt.instance<FinancesRepository>(),
        session: GetIt.instance<AuthSession>(),
      )..load(),
      child: const _RenterPaymentsView(),
    );
  }
}

class _RenterPaymentsView extends StatelessWidget {
  const _RenterPaymentsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PageAppBar(title: 'Payment history'),
      body: BlocBuilder<RenterPaymentsCubit, RenterPaymentsState>(
        builder: (context, state) => switch (state) {
          RenterPaymentsLoading() => const LoadingView(),
          RenterPaymentsFailure(:final failure) => ErrorView(
            message: failure.message,
            onRetry: () => context.read<RenterPaymentsCubit>().load(),
          ),
          RenterPaymentsEmpty() => const EmptyState(
            icon: Icons.payments_outlined,
            title: 'No payment history',
            message: 'Your rental payments, refunds and caution settlements will appear here.',
          ),
          RenterPaymentsLoaded(:final items) => ListView.separated(
            padding: Responsive.pagePadding(context)
                .copyWith(top: AppSpacing.md, bottom: AppSpacing.xl),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final item = items[index];
              return _PaymentItemTile(item: item);
            },
          ),
        },
      ),
    );
  }
}

class _PaymentItemTile extends StatelessWidget {
  const _PaymentItemTile({required this.item});

  final RenterPaymentItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final entry = item.entry;

    final kind = item.kind;
    final tone = switch (kind) {
      RenterPaymentKind.payment => StatusTone.active,
      RenterPaymentKind.cautionRefund ||
      RenterPaymentKind.cancellationRefund => StatusTone.info,
      RenterPaymentKind.claimDeduction => StatusTone.caution,
      RenterPaymentKind.lateFee => StatusTone.danger,
    };
    final sign = kind.isCredit ? '+' : '-';

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        onTap: () => context.push(RouteNames.booking(entry.bookingId)),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StatusChip(label: kind.label, tone: tone),
                      const SizedBox(width: AppSpacing.xs),
                      StatusChip(
                        label: entry.status.label,
                        tone: entry.status == TransactionStatus.success
                            ? StatusTone.neutral
                            : StatusTone.danger,
                      ),
                    ],
                  ),
                  Text(
                    Formatters.date(entry.at),
                    style: AppTextStyles.caption.copyWith(color: colors.muted),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.bookingReference ?? entry.reference,
                          style: AppTextStyles.cardTitle.copyWith(
                            color: colors.ink,
                          ),
                        ),
                        if (item.vehicleName != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.vehicleName!,
                            style: AppTextStyles.caption.copyWith(
                              color: colors.muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    '$sign${Formatters.rwf(entry.amount)}',
                    style: AppTextStyles.cardTitle.copyWith(
                      color: colors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
