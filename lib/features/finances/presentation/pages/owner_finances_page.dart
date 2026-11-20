import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:veloce/core/data/services/vehicle_lookup.dart';
import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/layout/responsive.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/error_view.dart';
import 'package:veloce/core/widgets/loading_view.dart';
import 'package:veloce/core/widgets/page_app_bar.dart';

import '../../domain/enums/finance_period.dart';
import '../../domain/enums/finance_view_mode.dart';
import '../../domain/repositories/finances_repository.dart';
import '../bloc/finances_bloc.dart';
import '../widgets/finance_chart.dart';
import '../widgets/finance_tiles.dart';
import '../widgets/finance_transactions_table.dart';
import '../widgets/per_car_share_list.dart';

class OwnerFinancesPage extends StatelessWidget {
  const OwnerFinancesPage({this.carId, super.key});

  final String? carId;

  @override
  Widget build(BuildContext context) {
    if (!GetIt.instance.isRegistered<FinancesRepository>() ||
        !GetIt.instance.isRegistered<AuthSession>() ||
        !GetIt.instance.isRegistered<VehicleLookup>()) {
      return const Scaffold(
        appBar: PageAppBar(title: 'Finances'),
        body: SizedBox.shrink(),
      );
    }
    return BlocProvider(
      create: (_) => FinancesBloc(
        repository: GetIt.instance<FinancesRepository>(),
        session: GetIt.instance<AuthSession>(),
        vehicleLookup: GetIt.instance<VehicleLookup>(),
        vehicleId: carId,
      )..add(FinancesStarted(vehicleId: carId)),
      child: const _OwnerFinancesView(),
    );
  }
}

class _OwnerFinancesView extends StatelessWidget {
  const _OwnerFinancesView();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return BlocBuilder<FinancesBloc, FinancesState>(
      builder: (context, state) {
        final title = state.vehicleId != null ? 'Car finances' : 'Finances';

        return Scaffold(
          appBar: PageAppBar(title: title),
          body: switch (state.status) {
            FinancesStatus.initial ||
            FinancesStatus.loading => const LoadingView(),
            FinancesStatus.failure => ErrorView(
              message: state.failure?.message ?? 'Could not load finances.',
              onRetry: () =>
                  context.read<FinancesBloc>().add(const FinancesRefreshed()),
            ),
            FinancesStatus.loaded => RefreshIndicator(
              onRefresh: () async {
                context.read<FinancesBloc>().add(const FinancesRefreshed());
              },
              child: ListView(
                padding: Responsive.pagePadding(context)
                    .copyWith(top: AppSpacing.md, bottom: AppSpacing.xl),
                children: [
                  // Single-car info banner if viewing car finances
                  if (state.vehicle != null) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: colors.line),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${state.vehicle!.make} ${state.vehicle!.model} (${state.vehicle!.year})',
                                  style: AppTextStyles.cardTitle,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  state.vehicle!.plate,
                                  style: AppTextStyles.caption.copyWith(
                                    color: colors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Period toggle: This month / This year
                  SegmentedButton<FinancePeriod>(
                    segments: const [
                      ButtonSegment(
                        value: FinancePeriod.thisMonth,
                        label: Text('This month'),
                      ),
                      ButtonSegment(
                        value: FinancePeriod.thisYear,
                        label: Text('This year'),
                      ),
                    ],
                    selected: {state.period},
                    onSelectionChanged: (selected) {
                      context.read<FinancesBloc>().add(
                        FinancesPeriodChanged(selected.first),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Two figures: Total earned, Total losses
                  FinanceTiles(
                    totalEarned: state.summary?.totalEarned ?? 0,
                    totalLosses: state.summary?.totalLosses ?? 0,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // View toggle: Chart / Table
                  SegmentedButton<FinanceViewMode>(
                    segments: const [
                      ButtonSegment(
                        value: FinanceViewMode.chart,
                        icon: Icon(Icons.bar_chart),
                        label: Text('Chart'),
                      ),
                      ButtonSegment(
                        value: FinanceViewMode.table,
                        icon: Icon(Icons.table_chart_outlined),
                        label: Text('Table'),
                      ),
                    ],
                    selected: {state.viewMode},
                    onSelectionChanged: (selected) {
                      context.read<FinancesBloc>().add(
                        FinancesViewModeChanged(selected.first),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Chart or Table view
                  if (state.viewMode == FinanceViewMode.chart) ...[
                    FinanceChart(
                      transactions: state.summary?.transactions ?? [],
                      period: state.period,
                    ),
                  ] else ...[
                    FinanceTransactionsTable(
                      transactions: state.summary?.transactions ?? [],
                      previewLimit: 5,
                      onViewAll: () {
                        if (state.vehicleId != null) {
                          context.push(
                            RouteNames.ownerCarTransactions(state.vehicleId!),
                          );
                        } else {
                          context.push(RouteNames.ownerTransactions);
                        }
                      },
                    ),
                  ],

                  // Per-car list (only on all-cars screen)
                  if (state.vehicleId == null &&
                      state.summary?.carShares != null &&
                      state.summary!.carShares.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xl),
                    PerCarShareList(carShares: state.summary!.carShares),
                  ],
                ],
              ),
            ),
          },
        );
      },
    );
  }
}
