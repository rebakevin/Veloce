import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/widgets/empty_state.dart';
import 'package:veloce/core/widgets/error_view.dart';
import 'package:veloce/core/widgets/loading_view.dart';
import 'package:veloce/core/widgets/page_app_bar.dart';
import 'package:veloce/core/widgets/primary_button.dart';

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
                  padding: const EdgeInsets.all(AppSpacing.gutter),
                  children: [
                    if (detail.vehicle.videoUrl != null) ...[
                      PrimaryButton(
                        label: 'Play walkaround video',
                        onPressed: () {
                          unawaited(
                            launchUrl(
                              Uri.parse(detail.vehicle.videoUrl!),
                              mode: LaunchMode.externalApplication,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: detail.photos.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: AppSpacing.sm,
                            crossAxisSpacing: AppSpacing.sm,
                            childAspectRatio: 4 / 3,
                          ),
                      itemBuilder: (context, index) => ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: CachedNetworkImage(
                          imageUrl: detail.photos[index].url,
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
                  ],
                ),
        ),
      },
    );
  }
}
