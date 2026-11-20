import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/widgets/error_view.dart';
import 'package:veloce/core/widgets/loading_view.dart';
import 'package:veloce/core/widgets/page_app_bar.dart';
import 'package:veloce/core/widgets/primary_button.dart';

import '../../domain/entities/car_detail_args.dart';
import '../bloc/car_detail_bloc.dart';
import '../widgets/availability_calendar.dart';
import '../widgets/discovery_scope.dart';

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
                const SizedBox(height: AppSpacing.sm),
                Text(
                  state.dateError!,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
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
