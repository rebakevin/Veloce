import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

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
import '../widgets/availability_calendar.dart';
import '../widgets/booking_terms.dart';
import '../widgets/car_photo_carousel.dart';
import '../widgets/discovery_scope.dart';
import '../widgets/long_rental_note.dart';
import '../widgets/owner_block.dart';

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
    return Scaffold(
      appBar: PageAppBar(
        title: '${vehicle.make} ${vehicle.model}',
        actions: [
          IconButton(
            tooltip: 'All photos and video',
            onPressed: () => context.push(RouteNames.carMedia(vehicle.id)),
            icon: const Icon(Icons.photo_library_outlined),
          ),
        ],
      ),
      bottomNavigationBar: _RequestBar(state: state),
      body: ListView(
        children: [
          CarPhotoCarousel(
            photos: detail.photos,
            heroTag: 'car-photo-${vehicle.id}',
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '${vehicle.make} ${vehicle.model} · ${vehicle.year}',
                        style: AppTextStyles.title,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      '${Formatters.rwf(vehicle.dailyPrice)}/day',
                      style: AppTextStyles.cardTitle.copyWith(
                        color: context.colors.brandDeep,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${vehicle.transmission.label} · ${vehicle.seats} seats · '
                  '${vehicle.type.label} · ${vehicle.fuel.label}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.colors.muted,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    StatusChip(
                      label: vehicle.neighbourhood,
                      tone: StatusTone.neutral,
                    ),
                    const StatusChip(
                      label: 'Self-drive',
                      tone: StatusTone.info,
                    ),
                    if (state.isOwner)
                      const StatusChip(
                        label: 'Your car · preview',
                        tone: StatusTone.caution,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                if (vehicle.description.isNotEmpty) ...[
                  Text(vehicle.description, style: AppTextStyles.body),
                  const SizedBox(height: AppSpacing.lg),
                ],
                const SectionHeader(title: 'Specs'),
                _Specs(detail: detail),
                if (vehicle.features.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  const SectionHeader(title: 'Features'),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final feature in vehicle.features)
                        Chip(label: Text(feature)),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                const SectionHeader(title: 'Rental rules'),
                _Rules(detail: detail),
                const SizedBox(height: AppSpacing.lg),
                OwnerBlock(
                  owner: detail.owner,
                  onTap: () => context.push(RouteNames.user(detail.owner.id)),
                ),
                const SizedBox(height: AppSpacing.lg),
                AvailabilityCalendar(
                  detail: detail,
                  start: state.start,
                  end: state.end,
                  onChanged: (start, end) => context.read<CarDetailBloc>().add(
                    CarDetailDatesChanged(start, end),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => _openDates(context, state),
                    icon: const Icon(Icons.edit_calendar_outlined),
                    label: const Text('Change dates'),
                  ),
                ),
                if (state.dateError != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    state.dateError!,
                    style: AppTextStyles.caption.copyWith(
                      color: context.colors.danger,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                LongRentalNote(detail: detail),
                if (state.quote != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  const SectionHeader(title: 'Price breakdown'),
                  if (state.quote!.dailyRateApplied < vehicle.dailyPrice)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text(
                        'Long-rental rate applied: '
                        '${Formatters.rwf(state.quote!.dailyRateApplied)} per day',
                        style: AppTextStyles.caption.copyWith(
                          color: context.colors.brandDeep,
                        ),
                      ),
                    ),
                  PriceBreakdown(quote: state.quote!),
                ],
                if (!state.isOwner) ...[
                  const SizedBox(height: AppSpacing.lg),
                  BookingTerms(
                    accepted: state.termsAccepted,
                    onChanged: (value) => context.read<CarDetailBloc>().add(
                      CarDetailTermsChanged(value),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
              ],
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

class _Specs extends StatelessWidget {
  const _Specs({required this.detail});

  final VehicleDetail detail;

  @override
  Widget build(BuildContext context) {
    final vehicle = detail.vehicle;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        Chip(label: Text(vehicle.transmission.label)),
        Chip(label: Text('${vehicle.seats} seats')),
        Chip(label: Text(vehicle.fuel.label)),
        Chip(label: Text(vehicle.type.label)),
        Chip(label: Text(vehicle.plate)),
      ],
    );
  }
}

class _Rules extends StatelessWidget {
  const _Rules({required this.detail});

  final VehicleDetail detail;

  @override
  Widget build(BuildContext context) {
    final vehicle = detail.vehicle;
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Rule(label: 'Fuel', value: vehicle.fuelRule),
        _Rule(label: 'Smoking', value: vehicle.smoking),
        for (final extra in vehicle.extras) _Rule(label: 'Rule', value: extra),
        if (vehicle.rulesFileUrl != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                unawaited(
                  launchUrl(
                    Uri.parse(vehicle.rulesFileUrl!),
                    mode: LaunchMode.externalApplication,
                  ),
                );
              },
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Open rental instructions PDF'),
            ),
          ),
        TextButton.icon(
          onPressed: () => context.push(RouteNames.carReviews(vehicle.id)),
          icon: const Icon(Icons.reviews_outlined),
          label: const Text('Read car reviews'),
        ),
        if (vehicle.rulesFileUrl == null) const SizedBox.shrink(),
        if (vehicle.fuelRule.isEmpty && vehicle.smoking.isEmpty)
          Text(
            'Ask the owner about any extra rules before pickup.',
            style: AppTextStyles.bodySmall.copyWith(color: colors.muted),
          ),
      ],
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 76, child: Text(label, style: AppTextStyles.caption)),
          Expanded(child: Text(value, style: AppTextStyles.bodySmall)),
        ],
      ),
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
