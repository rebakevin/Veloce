import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/empty_state.dart';
import 'package:veloce/core/widgets/error_view.dart';
import 'package:veloce/core/widgets/page_app_bar.dart';

import '../../domain/entities/car_detail_args.dart';
import '../../domain/entities/search_query.dart';
import '../../domain/entities/vehicle_card_data.dart';
import '../../domain/entities/vehicle_filters.dart';
import '../../domain/usecases/search_vehicles.dart';
import '../bloc/favourites_bloc.dart';
import '../bloc/results_bloc.dart';
import '../bloc/search_cubit.dart';
import '../widgets/car_card.dart';
import '../widgets/car_card_skeleton.dart';
import '../widgets/discovery_scope.dart';

/// Result list with count, filters, skeleton and empty/error states.
class ResultsPage extends StatelessWidget {
  const ResultsPage({
    super.key,
    this.initialQuery,
    this.initialFilters = VehicleFilters.none,
  });

  final SearchQuery? initialQuery;
  final VehicleFilters initialFilters;

  @override
  Widget build(BuildContext context) {
    return DiscoveryScope(
      child: _ResultsBody(
        initialQuery: initialQuery,
        initialFilters: initialFilters,
      ),
    );
  }
}

class _ResultsBody extends StatefulWidget {
  const _ResultsBody({
    required this.initialQuery,
    required this.initialFilters,
  });

  final SearchQuery? initialQuery;
  final VehicleFilters initialFilters;

  @override
  State<_ResultsBody> createState() => _ResultsBodyState();
}

class _ResultsBodyState extends State<_ResultsBody> {
  late final ResultsBloc _results;

  @override
  void initState() {
    super.initState();
    _results = ResultsBloc(
      search: GetIt.instance<SearchVehicles>(),
      initialQuery: widget.initialQuery ?? _fallbackQuery(),
      initialFilters: widget.initialFilters,
    )..add(const ResultsStarted());
  }

  @override
  void dispose() {
    _results.close();
    super.dispose();
  }

  SearchQuery _fallbackQuery() {
    final state = GetIt.instance<SearchCubit>().state;
    final now = GetIt.I<Clock>().now();
    final today = DateTime(now.year, now.month, now.day);
    return SearchQuery(
      area: state.area,
      typeChip: state.typeChip,
      start: state.start ?? today,
      end: state.end ?? today.add(const Duration(days: 3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ResultsBloc>.value(
      value: _results,
      child: BlocBuilder<ResultsBloc, ResultsState>(
        builder: (context, state) => Scaffold(
          appBar: PageAppBar(
            title: switch (state) {
              ResultsLoaded(:final cars) => '${cars.length} cars',
              ResultsEmpty() => 'No cars',
              _ => 'Cars',
            },
          ),
          body: Column(
            children: [
              _FilterBar(
                activeCount: state.filters.activeCount,
                onFilter: () => _openFilters(context, state),
              ),
              Expanded(child: _body(context, state)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, ResultsState state) {
    return switch (state) {
      ResultsLoading() => ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, _) => const CarCardSkeleton(),
      ),
      ResultsEmpty() => const EmptyState(
        icon: Icons.search_off_outlined,
        title: 'No cars match those dates',
        message: 'Try another area, different dates or fewer filters.',
      ),
      ResultsFailure(:final error) => ErrorView(
        message: error.message,
        onRetry: () =>
            context.read<ResultsBloc>().add(const ResultsRefreshed()),
      ),
      ResultsLoaded(:final cars, :final query) =>
        BlocBuilder<FavouritesBloc, FavouritesState>(
          builder: (context, favourites) => ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            itemCount: cars.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) =>
                _card(context, cars[index], query, favourites),
          ),
        ),
    };
  }

  Widget _card(
    BuildContext context,
    VehicleCardData car,
    SearchQuery query,
    FavouritesState favourites,
  ) {
    return CarCard(
      car: car,
      isFavourite: favourites.contains(car.vehicle.id),
      onFavourite: () =>
          context.read<FavouritesBloc>().add(FavouriteToggled(car.vehicle.id)),
      onTap: () => context.push(
        RouteNames.car(car.vehicle.id),
        extra: CarDetailArgs(start: query.start, end: query.end),
      ),
    );
  }

  Future<void> _openFilters(BuildContext context, ResultsState state) async {
    final filters = await context.push<VehicleFilters>(
      RouteNames.renterFilters,
      extra: state.filters,
    );
    if (filters == null || !mounted) return;
    _results.add(ResultsFiltersChanged(filters));
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.activeCount, required this.onFilter});

  final int activeCount;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.sm,
        AppSpacing.gutter,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              activeCount == 0 ? 'All cars' : '$activeCount filters active',
              style: AppTextStyles.caption.copyWith(color: colors.muted),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          SizedBox(
            width: 120,
            child: OutlinedButton.icon(
              onPressed: onFilter,
              icon: const Icon(Icons.tune, size: 18),
              label: const Text('Filters'),
            ),
          ),
        ],
      ),
    );
  }
}
