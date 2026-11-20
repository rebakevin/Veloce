import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:veloce/core/domain/entities/vehicle_photo.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';

/// Swipeable car photos. The first page carries the same Hero tag as the card.
class CarPhotoCarousel extends StatefulWidget {
  const CarPhotoCarousel({
    required this.photos,
    required this.heroTag,
    super.key,
  });

  final List<VehiclePhoto> photos;
  final String heroTag;

  @override
  State<CarPhotoCarousel> createState() => _CarPhotoCarouselState();
}

class _CarPhotoCarouselState extends State<CarPhotoCarousel> {
  final ValueNotifier<int> _index = ValueNotifier(0);

  @override
  void dispose() {
    _index.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final photos = widget.photos;
    if (photos.isEmpty) {
      return AspectRatio(
        aspectRatio: 16 / 10,
        child: ColoredBox(
          color: colors.brandWash,
          child: Icon(
            Icons.directions_car_outlined,
            size: 64,
            color: colors.brandDeep,
          ),
        ),
      );
    }
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16 / 10,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                itemCount: photos.length,
                onPageChanged: (value) => _index.value = value,
                itemBuilder: (context, index) {
                  final image = CachedNetworkImage(
                    imageUrl: photos[index].url,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => ColoredBox(color: colors.brandWash),
                    errorWidget: (_, _, _) => ColoredBox(
                      color: colors.brandWash,
                      child: Icon(
                        Icons.directions_car_outlined,
                        size: 64,
                        color: colors.brandDeep,
                      ),
                    ),
                  );
                  if (index != 0) return image;
                  return Hero(tag: widget.heroTag, child: image);
                },
              ),
              Positioned(
                right: AppSpacing.md,
                bottom: AppSpacing.md,
                child: ValueListenableBuilder<int>(
                  valueListenable: _index,
                  builder: (context, value, _) => DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.scrim,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 4,
                      ),
                      child: Text(
                        '${value + 1}/${photos.length}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
