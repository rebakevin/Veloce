import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:veloce/core/data/services/vehicle_lookup.dart';
import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/layout/responsive.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/widgets/error_view.dart';
import 'package:veloce/core/widgets/loading_view.dart';
import 'package:veloce/core/widgets/page_app_bar.dart';

import '../../domain/enums/finance_period.dart';
import '../../domain/repositories/finances_repository.dart';
import '../bloc/finances_bloc.dart';
import '../widgets/finance_transactions_table.dart';

class OwnerTransactionsPage extends StatelessWidget {
  const OwnerTransactionsPage({this.carId, super.key});

  final String? carId;

  @override
  Widget build(BuildContext context) {
    if (!GetIt.instance.isRegistered<FinancesRepository>() ||
        !GetIt.instance.isRegistered<AuthSession>() ||
        !GetIt.instance.isRegistered<VehicleLookup>()) {
      return const Scaffold(
        appBar: PageAppBar(title: 'Transactions'),
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
      child: const _OwnerTransactionsView(),
    );
  }
}

class _OwnerTransactionsView extends StatelessWidget {
  const _OwnerTransactionsView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FinancesBloc, FinancesState>(
      builder: (context, state) {
        final title = state.vehicleId != null
            ? 'Car transactions'
            : 'All transactions';

        return Scaffold(
          appBar: PageAppBar(title: title),
          body: switch (state.status) {
            FinancesStatus.initial ||
            FinancesStatus.loading => const LoadingView(),
            FinancesStatus.failure => ErrorView(
              message: state.failure?.message ?? 'Could not load transactions.',
              onRetry: () =>
                  context.read<FinancesBloc>().add(const FinancesRefreshed()),
            ),
            FinancesStatus.loaded => ListView(
              padding: Responsive.pagePadding(context)
                  .copyWith(top: AppSpacing.md, bottom: AppSpacing.xl),
              children: [
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
                const SizedBox(height: AppSpacing.lg),
                FinanceTransactionsTable(
                  transactions: state.summary?.transactions ?? [],
                ),
              ],
            ),
          },
        );
      },
    );
  }
}
