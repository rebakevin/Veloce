import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:veloce/core/domain/entities/vehicle.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/app_messenger.dart';
import 'package:veloce/core/widgets/empty_state.dart';
import 'package:veloce/core/widgets/error_view.dart';
import 'package:veloce/core/widgets/loading_view.dart';

import '../bloc/my_cars_bloc.dart';
import '../widgets/vehicle_card.dart';

class MyCarsPage extends StatelessWidget {
  const MyCarsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My cars')),
      body: BlocConsumer<MyCarsBloc, MyCarsState>(
        listener: (context, state) {
          if (state is MyCarsLoaded && state.notice != null) {
            GetIt.I<AppMessenger>().error(state.notice!);
            context.read<MyCarsBloc>().add(const MyCarsNoticeCleared());
          }
        },
        builder: (context, state) => switch (state) {
          MyCarsLoading() => const LoadingView(),
          MyCarsEmpty() => EmptyState(
            title: 'No cars yet',
            message: 'List your first car and renters can find it.',
            icon: Icons.directions_car_outlined,
            actionLabel: 'List a car',
            onAction: () => context.push(RouteNames.ownerCarNew),
          ),
          MyCarsFailure(:final message) => ErrorView(
            message: message,
            onRetry: () =>
                context.read<MyCarsBloc>().add(const MyCarsStarted()),
          ),
          MyCarsLoaded(
            :final vehicles,
            :final nextRentals,
            :final primaryPhotos,
            :final expiredIds,
          ) =>
            RefreshIndicator(
              onRefresh: () async {
                final bloc = context.read<MyCarsBloc>()
                  ..add(const MyCarsRefreshRequested());
                await bloc.stream.first.timeout(
                  const Duration(seconds: 5),
                  onTimeout: () => bloc.state,
                );
              },
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: vehicles.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) return const _ListCarButton();
                  final vehicle = vehicles[index - 1];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg - 2),
                    child: VehicleCard(
                      vehicle: vehicle,
                      nextRental: nextRentals[vehicle.id],
                      photoUrl: primaryPhotos[vehicle.id],
                      docsExpired: expiredIds.contains(vehicle.id),
                      onOpen: () => context.push(RouteNames.car(vehicle.id)),
                      onEdit: () =>
                          context.push(RouteNames.ownerCarEdit(vehicle.id)),
                      onAvailability: () => context.push(
                        RouteNames.ownerCarAvailability(vehicle.id),
                      ),
                      onDocuments: () => context.push(
                        RouteNames.ownerCarDocuments(vehicle.id),
                      ),
                      onToggleStatus: () => context.read<MyCarsBloc>().add(
                        MyCarsStatusToggled(vehicle),
                      ),
                      onRemove: () => _confirmRemove(context, vehicle),
                    ),
                  );
                },
              ),
            ),
        },
      ),
    );
  }
}

/// Compact "List a car" pill above the list, right-aligned as in the design.
class _ListCarButton extends StatelessWidget {
  const _ListCarButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg - 2),
      child: Align(
        alignment: Alignment.centerRight,
        child: FilledButton(
          onPressed: () => context.push(RouteNames.ownerCarNew),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, AppSizes.iconControl),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg + 2),
            textStyle: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          child: const Text('List a car'),
        ),
      ),
    );
  }
}

Future<void> _confirmRemove(BuildContext context, Vehicle vehicle) async {
  final bloc = context.read<MyCarsBloc>();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: const Text('Remove this car?'),
      content: Text(
        '${vehicle.plate} will be removed with its photos and documents. '
        'This cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialog, false),
          child: const Text('Keep car'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialog, true),
          child: const Text('Remove'),
        ),
      ],
    ),
  );
  if (confirmed == true) bloc.add(MyCarsRemoveRequested(vehicle.id));
}
