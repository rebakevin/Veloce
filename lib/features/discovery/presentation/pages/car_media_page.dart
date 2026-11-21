import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/empty_state.dart';
import 'package:veloce/core/widgets/error_view.dart';
import 'package:veloce/core/widgets/loading_view.dart';
import 'package:veloce/core/widgets/page_app_bar.dart';

import '../bloc/car_detail_bloc.dart';
import '../widgets/discovery_scope.dart';

/// All photos and the walkaround video for one car.
class CarMediaPage extends StatelessWidget {
  const CarMediaPage({required this.vehicleId, super.key});

  final String vehicleId;

  @override
  Widget build(BuildContext context) {
    return DiscoveryScope(
      child: BlocProvider<CarDetailBloc>(
        create: (_) =>
            GetIt.instance<CarDetailBloc>(param1: vehicleId, param2: null)
              ..add(const CarDetailStarted()),
        child: const _MediaBody(),
      ),
    );
  }
}

class _MediaBody extends StatelessWidget {
  const _MediaBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CarDetailBloc, CarDetailState>(
      builder: (context, state) => switch (state) {
        CarDetailLoading() => const Scaffold(body: LoadingView()),
        CarDetailFailure(:final error) => Scaffold(
          appBar: const PageAppBar(title: 'Photos and video'),
          body: ErrorView(
            message: error.message,
            onRetry: () =>
                context.read<CarDetailBloc>().add(const CarDetailRetried()),
          ),
        ),
        CarDetailLoaded(:final detail) => Scaffold(
          appBar: const PageAppBar(title: 'Photos and video'),
          body: detail.photos.isEmpty
              ? const EmptyState(
                  icon: Icons.photo_library_outlined,
                  title: 'No photos yet',
                  message: 'The owner has not added photos for this car.',
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    0,
                    AppSpacing.gutter,
                    AppSpacing.xl,
                  ),
                  children: [
                    if (detail.vehicle.videoUrl != null) ...[
                      _VideoTile(url: detail.vehicle.videoUrl!),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Text(
                        'Photos · ${detail.photos.length}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: context.colors.muted,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    for (final photo in detail.photos)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          child: AspectRatio(
                            aspectRatio: 16 / 10,
                            child: CachedNetworkImage(
                              imageUrl: photo.url,
                              fit: BoxFit.cover,
                              placeholder: (_, _) =>
                                  ColoredBox(color: context.colors.brandWash),
                              errorWidget: (_, _, _) => ColoredBox(
                                color: context.colors.brandWash,
                                child: Icon(
                                  Icons.directions_car_outlined,
                                  color: context.colors.brandDeep,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      },
    );
  }
}

/// The walkaround video block: a round Play button on a brand wash.
class _VideoTile extends StatelessWidget {
  const _VideoTile({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ColoredBox(
          color: colors.brandWash,
          child: Center(
            child: Material(
              color: colors.surface,
              shape: const CircleBorder(),
              child: IconButton(
                tooltip: 'Play walkaround video',
                iconSize: 28,
                color: colors.brand,
                constraints: const BoxConstraints.tightFor(
                  width: 64,
                  height: 64,
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                onPressed: () => unawaited(
                  launchUrl(
                    Uri.parse(url),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
