import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/widgets/error_view.dart';
import 'package:veloce/core/widgets/section_header.dart';

import '../bloc/owner_cars_cubit.dart';
import 'car_card.dart';
import 'car_card_skeleton.dart';

/// Slot owned by Phase 3: an owner's published cars on `/user/:id`.
class OwnerCarsSection extends StatelessWidget {
  const OwnerCarsSection({required this.ownerId, super.key});

  final String ownerId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OwnerCarsCubit>(
      create: (_) => GetIt.instance<OwnerCarsCubit>(param1: ownerId)..load(),
      child: const _OwnerCarsBody(),
    );
  }
}

class _OwnerCarsBody extends StatelessWidget {
  const _OwnerCarsBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OwnerCarsCubit, OwnerCarsState>(
      builder: (context, state) => switch (state) {
        OwnerCarsLoading() => SizedBox(
          height: 280,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const [SizedBox(width: 280, child: CarCardSkeleton())],
          ),
        ),
        OwnerCarsEmpty() => const SizedBox.shrink(),
        OwnerCarsFailure(:final error) => ErrorView(
          message: error.message,
          onRetry: () => context.read<OwnerCarsCubit>().load(),
        ),
        OwnerCarsLoaded(:final cars) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Cars from this owner'),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 300,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: cars.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.md),
                itemBuilder: (context, index) {
                  final car = cars[index];
                  return CarCard(
                    width: 280,
                    car: car,
                    isFavourite: false,
                    onFavourite: () {},
                    onTap: () => context.push(RouteNames.car(car.vehicle.id)),
                  );
                },
              ),
            ),
          ],
        ),
      },
    );
  }
}
