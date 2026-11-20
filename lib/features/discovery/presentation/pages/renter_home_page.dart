import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/empty_state.dart';
import 'package:veloce/core/widgets/error_view.dart';
import 'package:veloce/core/widgets/primary_button.dart';
import 'package:veloce/features/auth/auth.dart';

import '../../domain/entities/car_detail_args.dart';
import '../../domain/entities/search_query.dart';
import '../../domain/entities/vehicle_card_data.dart';
import '../../domain/entities/vehicle_filters.dart';
import '../../domain/usecases/search_vehicles.dart';
import '../bloc/favourites_bloc.dart';
import '../bloc/results_bloc.dart';
import '../bloc/search_cubit.dart';
import '../bloc/search_state.dart';
import '../widgets/car_card.dart';
import '../widgets/car_card_skeleton.dart';
import '../widgets/discovery_scope.dart';
import '../widgets/renter_search_form.dart';
import '../widgets/type_chip_row.dart';

/// Renter tab root: greeting, search card, type chips, Explore/Saved.
class RenterHomePage extends StatelessWidget {
  const RenterHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DiscoveryScope(child: _HomeBody());
  }
}

class _HomeBody extends StatefulWidget {
  const _HomeBody();

  @override
  State<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<_HomeBody> {
  late final ResultsBloc _results;

  @override
  void initState() {
    super.initState();
    final search = GetIt.instance<SearchCubit>();
    _results = ResultsBloc(
      search: GetIt.instance<SearchVehicles>(),
      initialQuery: _queryFor(search.state),
      initialFilters: VehicleFilters.none,
    )..add(const ResultsStarted());
  }

  @override
  void dispose() {
    _results.close();
    super.dispose();
  }

  static SearchQuery _queryFor(SearchState state) {
    final now = DateTime.now();
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
      child: BlocListener<SearchCubit, SearchState>(
        listenWhen: (previous, current) =>
            previous.area != current.area ||
            previous.start != current.start ||
            previous.end != current.end ||
            previous.typeChip != current.typeChip,
        listener: (context, state) =>
            _results.add(ResultsQueryChanged(_queryFor(state))),
        child: DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(title: const Text('Veloce')),
            body: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.gutter,
                      AppSpacing.md,
                      AppSpacing.gutter,
                      0,
                    ),
                    child: _Header(onSearch: () => unawaited(_search())),
                  ),
                ),
                const SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabHeader(),
                ),
              ],
              body: const TabBarView(children: [_ExploreTab(), _SavedTab()]),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _search() async {
    final search = context.read<SearchCubit>();
    final query = search.state.query;
    if (query == null) return;
    await search.savePreferences();
    if (!mounted) return;
    unawaited(context.push(RouteNames.renterResults, extra: query));
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onSearch});

  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final auth = context.watch<AuthBloc>().state;
    final name = auth is AuthAuthenticated ? auth.account.name : '';
    final firstName = name
        .split(RegExp(r'\s+'))
        .firstWhere((part) => part.isNotEmpty, orElse: () => 'there');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hi, $firstName', style: AppTextStyles.display),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Find the right car for your next trip around Kigali.',
          style: AppTextStyles.body.copyWith(color: colors.muted),
        ),
        const SizedBox(height: AppSpacing.lg),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                BlocBuilder<SearchCubit, SearchState>(
                  builder: (context, state) => RenterSearchForm(
                    state: state,
                    onAreaChanged: (area) =>
                        context.read<SearchCubit>().areaChanged(area),
                    onDatesChanged: (start, end) =>
                        context.read<SearchCubit>().datesChanged(start, end),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                BlocBuilder<SearchCubit, SearchState>(
                  builder: (context, state) => Align(
                    alignment: Alignment.centerLeft,
                    child: HomeTypeChips(
                      selected: state.typeChip,
                      onSelected: (type) =>
                          context.read<SearchCubit>().typeChipChanged(type),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                BlocBuilder<SearchCubit, SearchState>(
                  builder: (context, state) => PrimaryButton(
                    label: 'Search cars',
                    onPressed: state.query == null ? null : onSearch,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const Text('Explore cars', style: AppTextStyles.heading),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}

class _ExploreTab extends StatelessWidget {
  const _ExploreTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ResultsBloc, ResultsState>(
      builder: (context, state) => switch (state) {
        ResultsLoading() => const _CardListSkeleton(),
        ResultsEmpty() => const EmptyState(
          icon: Icons.search_off_outlined,
          title: 'No cars match those dates',
          message: 'Try another area or a different date range.',
        ),
        ResultsFailure(:final error) => ErrorView(
          message: error.message,
          onRetry: () =>
              context.read<ResultsBloc>().add(const ResultsRefreshed()),
        ),
        ResultsLoaded(:final cars, :final query) => _ResultsList(
          cars: cars,
          query: query,
          showHowItWorks: true,
        ),
      },
    );
  }
}

class _SavedTab extends StatelessWidget {
  const _SavedTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FavouritesBloc, FavouritesState>(
      builder: (context, state) => switch (state) {
        FavouritesLoading() => const _CardListSkeleton(),
        FavouritesFailure(:final error) => ErrorView(
          message: error.message,
          onRetry: () =>
              context.read<FavouritesBloc>().add(const FavouritesStarted()),
        ),
        FavouritesLoaded(:final cars) when cars.isEmpty => const EmptyState(
          icon: Icons.favorite_border_rounded,
          title: 'No saved cars yet',
          message: 'Tap a heart on a car to save it here.',
        ),
        FavouritesLoaded(:final cars) => _SavedList(cars: cars),
      },
    );
  }
}

class _ResultsList extends StatelessWidget {
  const _ResultsList({
    required this.cars,
    required this.query,
    this.showHowItWorks = false,
  });

  final List<VehicleCardData> cars;
  final SearchQuery query;
  final bool showHowItWorks;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FavouritesBloc, FavouritesState>(
      builder: (context, favourites) => ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        itemCount: cars.length + (showHowItWorks ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          if (index == cars.length) return const _HowItWorks();
          final car = cars[index];
          return CarCard(
            car: car,
            isFavourite: favourites.contains(car.vehicle.id),
            onFavourite: () => context.read<FavouritesBloc>().add(
              FavouriteToggled(car.vehicle.id),
            ),
            onTap: () => context.push(
              RouteNames.car(car.vehicle.id),
              extra: CarDetailArgs(start: query.start, end: query.end),
            ),
          );
        },
      ),
    );
  }
}

class _SavedList extends StatelessWidget {
  const _SavedList({required this.cars});

  final List<VehicleCardData> cars;

  @override
  Widget build(BuildContext context) {
    final query = context.read<SearchCubit>().query;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = query?.start ?? today;
    final end = query?.end ?? today.add(const Duration(days: 3));
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      itemCount: cars.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final car = cars[index];
        return CarCard(
          car: car,
          isFavourite: true,
          onFavourite: () => context.read<FavouritesBloc>().add(
            FavouriteToggled(car.vehicle.id),
          ),
          onTap: () => context.push(
            RouteNames.car(car.vehicle.id),
            extra: CarDetailArgs(start: start, end: end),
          ),
        );
      },
    );
  }
}

class _CardListSkeleton extends StatelessWidget {
  const _CardListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      itemCount: 3,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, _) => const CarCardSkeleton(),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const steps = [
      'Find a car and pick your dates.',
      'Send a request and wait for the owner.',
      'Pay only after approval, then meet for pickup.',
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.brandWash,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('How it works', style: AppTextStyles.cardTitle),
            const SizedBox(height: AppSpacing.sm),
            for (var index = 0; index < steps.length; index++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  '${index + 1}. ${steps[index]}',
                  style: AppTextStyles.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TabHeader extends SliverPersistentHeaderDelegate {
  const _TabHeader();

  @override
  double get minExtent => kTextTabBarHeight;

  @override
  double get maxExtent => kTextTabBarHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: const TabBar(
        tabs: [
          Tab(text: 'Explore'),
          Tab(text: 'Saved'),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_TabHeader oldDelegate) => false;
}
