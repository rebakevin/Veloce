import 'package:flutter/material.dart';

import 'package:veloce/core/domain/entities/vehicle_photo.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';

import 'car_photo_carousel.dart';

/// Full-bleed photo carousel with round Back and Save buttons on top, the
/// "Photos and video" pill, and the page sheet's rounded top edge overlapping
/// the bottom of the photo.
class CarPhotoHeader extends StatelessWidget {
  const CarPhotoHeader({
    required this.photos,
    required this.heroTag,
    required this.isFavourite,
    required this.onBack,
    required this.onFavourite,
    required this.onOpenMedia,
    super.key,
  });

  final List<VehiclePhoto> photos;
  final String heroTag;
  final bool isFavourite;
  final VoidCallback onBack;
  final VoidCallback onFavourite;
  final VoidCallback onOpenMedia;

  static const double _sheetOverlap = 24;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final top = MediaQuery.paddingOf(context).top + AppSpacing.sm;
    return Stack(
      children: [
        CarPhotoCarousel(photos: photos, heroTag: heroTag),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: _sheetOverlap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.ground,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.sheet),
              ),
            ),
          ),
        ),
        Positioned(
          left: AppSpacing.gutter,
          top: top,
          child: _RoundButton(
            tooltip: 'Back',
            icon: Icons.arrow_back,
            color: colors.ink,
            onPressed: onBack,
          ),
        ),
        Positioned(
          right: AppSpacing.gutter,
          top: top,
          child: _RoundButton(
            tooltip: isFavourite ? 'Remove from saved' : 'Save this car',
            icon: isFavourite
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            color: isFavourite ? colors.dangerAction : colors.brand,
            onPressed: onFavourite,
          ),
        ),
        Positioned(
          right: AppSpacing.gutter,
          bottom: _sheetOverlap + AppSpacing.sm,
          child: Material(
            color: colors.scrim,
            shape: const StadiumBorder(),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: onOpenMedia,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: AppSizes.iconControl,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg - 2,
                  ),
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      'Photos and video ›',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surface,
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        color: color,
        iconSize: 22,
        constraints: const BoxConstraints.tightFor(
          width: AppSizes.iconControl,
          height: AppSizes.iconControl,
        ),
        icon: Icon(icon),
        onPressed: onPressed,
      ),
    );
  }
}
