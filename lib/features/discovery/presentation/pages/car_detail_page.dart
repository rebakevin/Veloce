import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:veloce/core/formatting/formatters.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/error_view.dart';
import 'package:veloce/core/widgets/loading_view.dart';
import 'package:veloce/core/widgets/page_app_bar.dart';
import 'package:veloce/core/widgets/price_breakdown.dart';
import 'package:veloce/core/widgets/primary_button.dart';
import 'package:veloce/core/widgets/section_header.dart';
import 'package:veloce/core/widgets/status_chip.dart';

import '../../domain/entities/booking_request_draft.dart';
import '../../domain/entities/car_detail_args.dart';
import '../../domain/entities/vehicle_detail.dart';
import '../bloc/car_detail_bloc.dart';
import '../bloc/favourites_bloc.dart';
import '../widgets/availability_calendar.dart';
import '../widgets/booking_terms.dart';
import '../widgets/car_photo_header.dart';
import '../widgets/car_rules_card.dart';
import '../widgets/car_specs_grid.dart';
import '../widgets/discovery_scope.dart';
import '../widgets/link_row_card.dart';
import '../widgets/long_rental_note.dart';
import '../widgets/owner_block.dart';
import '../widgets/pickup_card.dart';

/// Car detail. Owners see a read-only preview of their own car.
class CarDetailPage extends StatelessWidget {
  const CarDetailPage({required this.vehicleId, super.key, this.dates});

  final String vehicleId;
  final CarDetailArgs? dates;

  @override
  Widget build(BuildContext context) {
    return DiscoveryScope(
      child: BlocProvider<CarDetailBloc>(
        create: (_) =>
            GetIt.instance<CarDetailBloc>(param1: vehicleId, param2: dates)
              ..add(const CarDetailStarted()),
        child: const _CarDetailBody(),
      ),
    );
  }
}

class _CarDetailBody extends StatelessWidget {
  const _CarDetailBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CarDetailBloc, CarDetailState>(
      builder: (context, state) => switch (state) {
        CarDetailLoading() => const Scaffold(body: LoadingView()),
        CarDetailFailure(:final error) => Scaffold(
          appBar: const PageAppBar(title: 'Car'),
          body: ErrorView(
            message: error.message,
            onRetry: () =>
                context.read<CarDetailBloc>().add(const CarDetailRetried()),
          ),
        ),
        CarDetailLoaded() => _LoadedDetail(state: state),
      },
    );
  }
}

class _LoadedDetail extends StatelessWidget {
  const _LoadedDetail({required this.state});

  final CarDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    final detail = state.detail;
    final vehicle = detail.vehicle;
    final favourites = context.watch<FavouritesBloc>().state;
    final colors = context.colors;
    return Scaffold(
      bottomNavigationBar: _RequestBar(state: state),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          CarPhotoHeader(
            photos: detail.photos,
            heroTag: 'car-photo-${vehicle.id}',
            isFavourite: favourites.contains(vehicle.id),
            onBack: context.pop,
            onFavourite: () => context.read<FavouritesBloc>().add(
              FavouriteToggled(vehicle.id),
            ),
            onOpenMedia: () => context.push(RouteNames.carMedia(vehicle.id)),
          ),
          ColoredBox(
            color: colors.ground,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                0,
                AppSpacing.gutter,
                AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpacing.md + 2,
                children: [
                  _Heading(detail: detail),
                  if (state.isOwner)
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: StatusChip(
                        label: 'Your car · preview',
                        tone: StatusTone.caution,
                      ),
                    ),
                  if (vehicle.description.isNotEmpty)
                    Text(
                      vehicle.description,
                      style: AppTextStyles.body.copyWith(color: colors.body),
                    ),
                  AvailabilityCalendar(
                    detail: detail,
                    start: state.start,
                    end: state.end,
                    onChanged: (start, end) => context
                        .read<CarDetailBloc>()
                        .add(CarDetailDatesChanged(start, end)),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _openDates(context, state),
                      icon: const Icon(Icons.edit_calendar_outlined),
                      label: const Text('Change dates'),
                    ),
                  ),
                  if (state.dateError != null)
                    Text(
                      state.dateError!,
                      style: AppTextStyles.caption.copyWith(
                        color: colors.danger,
                      ),
                    ),
                  LinkRowCard(
                    title: 'Media',
                    subtitle: 'Photos and video',
                    onTap: () => context.push(RouteNames.carMedia(vehicle.id)),
                  ),
                  CarSpecsGrid(detail: detail),
                  if (vehicle.features.isNotEmpty)
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final feature in vehicle.features)
                          StatusChip(label: feature, tone: StatusTone.info),
                      ],
                    ),
                  OwnerBlock(
                    owner: detail.owner,
                    onTap: () => context.push(RouteNames.user(detail.owner.id)),
                  ),
                  LinkRowCard(
                    title: 'Car reviews',
                    subtitle: vehicle.ratingCount == 0
                        ? 'No reviews yet'
                        : '★ ${vehicle.ratingAvg.toStringAsFixed(1)} · '
                              '${vehicle.ratingCount} '
                              '${vehicle.ratingCount == 1 ? 'review' : 'reviews'}',
                    onTap: () =>
                        context.push(RouteNames.carReviews(vehicle.id)),
                  ),
                  CarRulesCard(detail: detail),
                  PickupCard(neighbourhood: vehicle.neighbourhood),
                  LongRentalNote(detail: detail),
                  if (state.quote != null) _Quote(state: state),
                  if (!state.isOwner)
                    BookingTerms(
                      accepted: state.termsAccepted,
                      onChanged: (value) => context.read<CarDetailBloc>().add(
                        CarDetailTermsChanged(value),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDates(BuildContext context, CarDetailLoaded state) async {
    final start = state.start;
    final end = state.end;
    final dates = start == null || end == null
        ? null
        : CarDetailArgs(start: start, end: end);
    final picked = await context.push<CarDetailArgs>(
      RouteNames.carDates(state.detail.vehicle.id),
      extra: dates,
    );
    if (picked == null || !context.mounted) return;
    context.read<CarDetailBloc>().add(
      CarDetailDatesChanged(picked.start, picked.end),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.detail});

  final VehicleDetail detail;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final vehicle = detail.vehicle;
    final rating = vehicle.ratingCount == 0
        ? 'New'
        : '★ ${vehicle.ratingAvg.toStringAsFixed(1)} '
              '(${vehicle.ratingCount} reviews)';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${vehicle.make} ${vehicle.model} · ${vehicle.year}',
          style: AppTextStyles.title.copyWith(color: colors.ink, fontSize: 28),
        ),
        const SizedBox(height: AppSpacing.sm - 2),
        Text(
          '$rating · ${vehicle.neighbourhood}, Kigali',
          style: AppTextStyles.body.copyWith(
            color: colors.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm + 2),
        Text.rich(
          TextSpan(
            text: Formatters.rwf(vehicle.dailyPrice),
            children: [
              TextSpan(
                text: ' / day',
                style: AppTextStyles.bodySmall.copyWith(
                  color: colors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          style: AppTextStyles.title.copyWith(
            color: colors.brand,
            fontSize: 26,
          ),
        ),
      ],
    );
  }
}

class _Quote extends StatelessWidget {
  const _Quote({required this.state});

  final CarDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    final quote = state.quote!;
    final vehicle = state.detail.vehicle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Price breakdown'),
        if (quote.dailyRateApplied < vehicle.dailyPrice)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              'Long-rental rate applied: '
              '${Formatters.rwf(quote.dailyRateApplied)} per day',
              style: AppTextStyles.caption.copyWith(
                color: context.colors.brandDeep,
              ),
            ),
          ),
        PriceBreakdown(quote: quote),
      ],
    );
  }
}

class _RequestBar extends StatelessWidget {
  const _RequestBar({required this.state});

  final CarDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (state.isOwner) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          child: Text(
            'This is your car. Renters see this page without booking controls.',
            style: AppTextStyles.caption.copyWith(color: colors.muted),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        child: PrimaryButton(
          label: 'Request booking',
          onPressed: state.canRequest ? () => _request(context) : null,
        ),
      ),
    );
  }

  void _request(BuildContext context) {
    final quote = state.quote;
    final start = state.start;
    final end = state.end;
    if (quote == null || start == null || end == null) return;
    final draft = BookingRequestDraft(
      vehicle: state.detail.vehicle,
      start: start,
      end: end,
      quote: quote,
    );
    context.push(RouteNames.carBook(state.detail.vehicle.id), extra: draft);
  }
}
