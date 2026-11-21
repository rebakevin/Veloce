import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:veloce/core/domain/entities/booking.dart';
import 'package:veloce/core/domain/entities/vehicle.dart';
import 'package:veloce/core/domain/enums/vehicle_status.dart';
import 'package:veloce/core/formatting/formatters.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/status_chip.dart';

class VehicleCard extends StatelessWidget {
  const VehicleCard({
    required this.vehicle,
    required this.onOpen,
    required this.onEdit,
    required this.onAvailability,
    required this.onDocuments,
    required this.onToggleStatus,
    required this.onRemove,
    this.nextRental,
    this.photoUrl,
    this.docsExpired = false,
    super.key,
  });

  final Vehicle vehicle;
  final Booking? nextRental;
  final String? photoUrl;

  /// The required papers lapsed: the car is hidden from renters until the
  /// owner replaces them.
  final bool docsExpired;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onAvailability;
  final VoidCallback onDocuments;
  final VoidCallback onToggleStatus;
  final VoidCallback onRemove;

  bool get _isPublished => vehicle.status == VehicleStatus.published;

  String get _availability {
    final from = vehicle.availableFrom;
    final to = vehicle.availableTo;
    if (from == null || to == null) return 'No dates set: hidden from search';
    return Formatters.dateRange(from, to);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CarPhoto(photoUrl: photoUrl, plate: vehicle.plate),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md + 2,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: Text(
                          '${vehicle.make} ${vehicle.model} · ${vehicle.year}',
                          style: AppTextStyles.cardTitle.copyWith(
                            color: colors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '${Formatters.rwf(vehicle.dailyPrice)}/day',
                        style: AppTextStyles.cardTitle.copyWith(
                          color: colors.brand,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm - 2,
                    runSpacing: AppSpacing.sm - 2,
                    children: [
                      StatusChip(
                        label: docsExpired
                            ? 'Paused: documents expired'
                            : vehicle.status.label,
                        tone: _isPublished && !docsExpired
                            ? StatusTone.active
                            : StatusTone.caution,
                      ),
                      _InfoPill(label: _availability),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          nextRental == null
                              ? 'No upcoming rental'
                              : 'Next rental: ${Formatters.dateRange(nextRental!.startDate, nextRental!.endDate)}',
                          style: AppTextStyles.caption.copyWith(
                            color: colors.muted,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right, color: colors.brand),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Wrap(
                spacing: AppSpacing.xs,
                children: [
                  TextButton(onPressed: onEdit, child: const Text('Edit')),
                  TextButton(
                    onPressed: onAvailability,
                    child: const Text('Availability'),
                  ),
                  TextButton(
                    onPressed: onDocuments,
                    child: Text(docsExpired ? 'Fix documents' : 'Documents'),
                  ),
                  TextButton(
                    onPressed: onToggleStatus,
                    child: Text(_isPublished ? 'Pause' : 'Resume'),
                  ),
                  TextButton(onPressed: onRemove, child: const Text('Remove')),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
        ),
      ),
    );
  }
}

/// Photo on top of the card with the plate as a caption, as in the design.
class _CarPhoto extends StatelessWidget {
  const _CarPhoto({required this.photoUrl, required this.plate});

  final String? photoUrl;
  final String plate;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: colors.sand,
            child: photoUrl == null
                ? Icon(Icons.directions_car_outlined, color: colors.muted)
                : CachedNetworkImage(
                    imageUrl: photoUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) =>
                        const Icon(Icons.directions_car_outlined),
                  ),
          ),
          Positioned(
            left: AppSpacing.md,
            bottom: AppSpacing.sm + 2,
            child: Text(
              plate,
              style: AppTextStyles.plate.copyWith(
                color: colors.inkSoft,
                fontSize: 11,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.ground,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md - 2,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(color: colors.ink),
        ),
      ),
    );
  }
}
