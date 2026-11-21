import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/brand_mark.dart';
import 'package:veloce/core/widgets/empty_state.dart';
import 'package:veloce/core/widgets/error_view.dart';
import 'package:veloce/core/widgets/pill_segmented.dart';
import 'package:veloce/core/widgets/primary_button.dart';
import 'package:veloce/features/auth/auth.dart';

import '../../domain/entities/car_detail_args.dart';
import '../../domain/entities/search_query.dart';
import '../../domain/entities/vehicle_card_data.dart';
import '../../domain/entities/vehicle_filters.dart';
import '../../domain/usecases/search_vehicles.dart';
import '../bloc/favourites_bloc.dart';
import '../bloc/home_tab_cubit.dart';
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
  final HomeTabCubit _tab = HomeTabCubit();

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
    unawaited(_tab.close());
    super.dispose();
  }

  /// The mock opens with today to three days later, so the tiles show them
  /// before the renter picks anything.
  static SearchState _withDefaultDates(SearchState state) {
    final query = _queryFor(state);
    return state.copyWith(start: query.start, end: query.end);
  }

  static SearchQuery _queryFor(SearchState state) {
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
    return MultiBlocProvider(
      providers: [
        BlocProvider<ResultsBloc>.value(value: _results),
        BlocProvider<HomeTabCubit>.value(value: _tab),
      ],
      child: BlocListener<SearchCubit, SearchState>(
        listenWhen: (previous, current) =>
            previous.area != current.area ||
            previous.start != current.start ||
            previous.end != current.end ||
            previous.typeChip != current.typeChip,
        listener: (context, state) =>
            _results.add(ResultsQueryChanged(_queryFor(state))),
        child: Scaffold(
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.gutter + AppSpacing.xs,
                      AppSpacing.sm,
                      AppSpacing.gutter + AppSpacing.xs,
                      0,
                    ),
                    child: BlocBuilder<HomeTabCubit, int>(
                      builder: (context, tab) => _Header(
                        tab: tab,
                        onTab: context.read<HomeTabCubit>().select,
                        onSearch: () => unawaited(_search()),
                      ),
                    ),
                  ),
                ),
                BlocBuilder<HomeTabCubit, int>(
                  builder: (context, tab) =>
                      tab == 0 ? const _ExploreTab() : const _SavedTab(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _search() async {
    final search = context.read<SearchCubit>();
    final query = _queryFor(search.state);
    await search.savePreferences();
    if (!mounted) return;
    unawaited(context.push(RouteNames.renterResults, extra: query));
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.tab,
    required this.onTab,
    required this.onSearch,
  });

  final int tab;
  final ValueChanged<int> onTab;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final auth = context.watch<AuthBloc>().state;
    final name = auth is AuthAuthenticated ? auth.account.name : '';
    final firstName = name
        .split(RegExp(r'\s+'))
        .firstWhere((part) => part.isNotEmpty, orElse: () => 'there');
    final saved = context.select<FavouritesBloc, int>(
      (bloc) => bloc.state.favouriteIds.length,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(child: BrandMark()),
        const SizedBox(height: AppSpacing.lg + 2),
        Text(
          'Muraho, $firstName',
          style: AppTextStyles.body.copyWith(
            color: colors.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Text('Where to next?', style: AppTextStyles.display),
        const SizedBox(height: AppSpacing.lg + 2),
        PillSegmented(
          labels: ['Explore', saved == 0 ? 'Saved' : 'Saved ($saved)'],
          selected: tab,
          onSelected: onTab,
        ),
        if (tab == 0) ...[
          const SizedBox(height: AppSpacing.lg + 2),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.sheet),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F1A1814),
                  blurRadius: 24,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  BlocBuilder<SearchCubit, SearchState>(
                    builder: (context, state) => RenterSearchForm(
                      state: _HomeBodyState._withDefaultDates(state),
                      onAreaChanged: (area) =>
                          context.read<SearchCubit>().areaChanged(area),
                      onDatesChanged: (start, end) =>
                          context.read<SearchCubit>().datesChanged(start, end),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PrimaryButton(
                    label: 'Search cars',
                    icon: Icons.search_rounded,
                    onPressed: onSearch,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg - 2),
          BlocBuilder<SearchCubit, SearchState>(
            builder: (context, state) => HomeTypeChips(
              selected: state.typeChip,
              onSelected: (type) =>
                  context.read<SearchCubit>().typeChipChanged(type),
            ),
          ),
          const SizedBox(height: AppSpacing.lg + 2),
          Text(
            'Available for your dates',
            style: AppTextStyles.heading.copyWith(color: colors.ink),
          ),
          const SizedBox(height: AppSpacing.md - 2),
        ] else
          const SizedBox(height: AppSpacing.lg),
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
        ResultsEmpty() => const _SliverMessage(
          EmptyState(
            icon: Icons.search_off_outlined,
            title: 'No cars match those dates',
            message: 'Try another area or a different date range.',
          ),
        ),
        ResultsFailure(:final error) => _SliverMessage(
          ErrorView(
            message: error.message,
            onRetry: () =>
                context.read<ResultsBloc>().add(const ResultsRefreshed()),
          ),
        ),
        ResultsLoaded(:final cars, :final query) => _CarSliver(
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
        FavouritesFailure(:final error) => _SliverMessage(
          ErrorView(
            message: error.message,
            onRetry: () =>
                context.read<FavouritesBloc>().add(const FavouritesStarted()),
          ),
        ),
        FavouritesLoaded(:final cars) when cars.isEmpty => const _SliverMessage(
          EmptyState(
            icon: Icons.favorite_border_rounded,
            title: 'Nothing saved yet',
            message: 'Tap a heart on a car to save it here.',
          ),
        ),
        FavouritesLoaded(:final cars) => _SavedList(cars: cars),
      },
    );
  }
}

class _SliverMessage extends StatelessWidget {
  const _SliverMessage(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      SliverFillRemaining(hasScrollBody: false, child: child);
}

/// Bottom space so the last card clears the floating tab bar.
const double _tabBarClearance = 120;

class _CarSliver extends StatelessWidget {
  const _CarSliver({
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
      builder: (context, favourites) => SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter + AppSpacing.xs,
          0,
          AppSpacing.gutter + AppSpacing.xs,
          _tabBarClearance,
        ),
        sliver: SliverList.separated(
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
    final now = GetIt.I<Clock>().now();
    final today = DateTime(now.year, now.month, now.day);
    final start = query?.start ?? today;
    final end = query?.end ?? today.add(const Duration(days: 3));
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter + AppSpacing.xs,
        0,
        AppSpacing.gutter + AppSpacing.xs,
        _tabBarClearance,
      ),
      sliver: SliverList.separated(
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
      ),
    );
  }
}

class _CardListSkeleton extends StatelessWidget {
  const _CardListSkeleton();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter + AppSpacing.xs,
        0,
        AppSpacing.gutter + AppSpacing.xs,
        _tabBarClearance,
      ),
      sliver: SliverList.separated(
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, _) => const CarCardSkeleton(),
      ),
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
