import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:veloce/core/formatting/formatters.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/error_view.dart';
import 'package:veloce/core/widgets/loading_view.dart';
import 'package:veloce/core/widgets/page_app_bar.dart';
import 'package:veloce/core/widgets/primary_button.dart';

import '../../domain/entities/car_detail_args.dart';
import '../bloc/car_detail_bloc.dart';
import '../widgets/availability_calendar.dart';
import '../widgets/discovery_scope.dart';
import '../widgets/info_card.dart';
import '../widgets/label_value_row.dart';

/// Date-only route for one car. Pops with the selected [CarDetailArgs].
class CarDatesPage extends StatelessWidget {
  const CarDatesPage({required this.vehicleId, super.key, this.dates});

  final String vehicleId;
  final CarDetailArgs? dates;

  @override
  Widget build(BuildContext context) {
    return DiscoveryScope(
      child: BlocProvider<CarDetailBloc>(
        create: (_) =>
            GetIt.instance<CarDetailBloc>(param1: vehicleId, param2: dates)
              ..add(const CarDetailStarted()),
        child: const _DatesBody(),
      ),
    );
  }
}

class _DatesBody extends StatelessWidget {
  const _DatesBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CarDetailBloc, CarDetailState>(
      builder: (context, state) => switch (state) {
        CarDetailLoading() => const Scaffold(body: LoadingView()),
        CarDetailFailure(:final error) => Scaffold(
          appBar: const PageAppBar(title: 'Select dates'),
          body: ErrorView(
            message: error.message,
            onRetry: () =>
                context.read<CarDetailBloc>().add(const CarDetailRetried()),
          ),
        ),
        CarDetailLoaded() => Scaffold(
          appBar: const PageAppBar(title: 'Select dates'),
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            children: [
              AvailabilityCalendar(
                detail: state.detail,
                start: state.start,
                end: state.end,
                onChanged: (start, end) => context.read<CarDetailBloc>().add(
                  CarDetailDatesChanged(start, end),
                ),
              ),
              if (state.dateError != null) ...[
                const SizedBox(height: AppSpacing.md),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.colors.dangerWash,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      state.dateError!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.colors.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
              if (state.start != null && state.end != null) ...[
                const SizedBox(height: AppSpacing.md),
                InfoCard(
                  child: LabelValueRow(
                    label: Formatters.dateRange(state.start!, state.end!),
                    value: '${state.end!.difference(state.start!).inDays} days',
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'Use these dates',
                onPressed: state.start == null || state.end == null
                    ? null
                    : () => context.pop(
                        CarDetailArgs(start: state.start!, end: state.end!),
                      ),
              ),
            ],
          ),
        ),
      },
    );
  }
}
