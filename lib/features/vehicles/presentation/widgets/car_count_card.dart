import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';

import '../bloc/car_count_cubit.dart';

class CarCountCard extends StatelessWidget {
  const CarCountCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.I<CarCountCubit>(),
      child: const _CarCountView(),
    );
  }
}

class _CarCountView extends StatelessWidget {
  const _CarCountView();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(RouteNames.ownerCars),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: BlocBuilder<CarCountCubit, CarCountState>(
            builder: (context, state) => Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Published cars',
                        style: AppTextStyles.cardTitle,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(_summary(state)),
                    ],
                  ),
                ),
                if (state is CarCountLoaded)
                  Text('${state.published}', style: AppTextStyles.heading),
                Icon(Icons.chevron_right, color: colors.brand),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _summary(CarCountState state) => switch (state) {
    CarCountLoading() => 'Loading your cars',
    CarCountFailure(:final message) => message,
    CarCountLoaded(published: 0, paused: 0) => 'List your first car',
    CarCountLoaded(paused: 0) => 'All your cars are live',
    CarCountLoaded(:final paused) => '$paused paused',
  };
}
