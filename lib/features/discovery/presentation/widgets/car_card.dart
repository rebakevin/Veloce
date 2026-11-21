import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:veloce/core/formatting/formatters.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/rating_stars.dart';

import '../../domain/entities/vehicle_card_data.dart';

/// Result/saved car card. The heart is driven by the caller so every card and
/// the Saved tab read the same [FavouritesBloc] state.
class CarCard extends StatelessWidget {
  const CarCard({
    required this.car,
    required this.isFavourite,
    required this.onFavourite,
    required this.onTap,
    super.key,
    this.width,
  });

  final VehicleCardData car;
  final bool isFavourite;
  final VoidCallback onFavourite;
  final VoidCallback onTap;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final vehicle = car.vehicle;
    return SizedBox(
      width: width,
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  Hero(
                    tag: 'car-photo-${vehicle.id}',
                    child: AspectRatio(
                      aspectRatio: 16 / 10,
                      child: _CarPhoto(url: car.photoUrl),
                    ),
                  ),
                  Positioned(
                    top: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: IconButton(
                      tooltip: isFavourite
                          ? 'Remove from saved'
                          : 'Save this car',
                      onPressed: onFavourite,
                      style: IconButton.styleFrom(
                        backgroundColor: colors.surface,
                        foregroundColor: isFavourite
                            ? colors.dangerAction
                            : colors.inkSoft,
                      ),
                      icon: Icon(
                        isFavourite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            '${vehicle.make} ${vehicle.model} · ${vehicle.year}',
                            style: AppTextStyles.cardTitle.copyWith(
                              color: colors.ink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text.rich(
                          TextSpan(
                            text: Formatters.rwf(vehicle.dailyPrice),
                            children: [
                              TextSpan(
                                text: '/day',
                                style: AppTextStyles.label.copyWith(
                                  color: colors.muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          style: AppTextStyles.cardTitle.copyWith(
                            color: colors.brand,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${vehicle.transmission.label} · ${vehicle.seats} seats · '
                      '${vehicle.type.label}',
                      style: AppTextStyles.caption.copyWith(
                        color: colors.muted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        RatingStars(
                          rating: vehicle.ratingAvg,
                          count: vehicle.ratingCount,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Icon(
                          Icons.place_outlined,
                          size: 16,
                          color: colors.muted,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            vehicle.neighbourhood,
                            style: AppTextStyles.caption.copyWith(
                              color: colors.muted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CarPhoto extends StatelessWidget {
  const _CarPhoto({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final url = this.url;
    if (url == null) {
      return ColoredBox(
        color: colors.brandWash,
        child: Icon(
          Icons.directions_car_outlined,
          size: 48,
          color: colors.brandDeep,
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, _) => ColoredBox(color: colors.brandWash),
      errorWidget: (_, _, _) => ColoredBox(
        color: colors.brandWash,
        child: Icon(
          Icons.directions_car_outlined,
          size: 48,
          color: colors.brandDeep,
        ),
      ),
    );
  }
}
