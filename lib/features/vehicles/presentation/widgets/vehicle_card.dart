import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:veloce/core/domain/entities/booking.dart';
import 'package:veloce/core/domain/entities/vehicle.dart';
import 'package:veloce/core/domain/enums/vehicle_status.dart';
import 'package:veloce/core/formatting/formatters.dart';
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
    return Card(
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (photoUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedNetworkImage(
                      imageUrl: photoUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) =>
                          const Icon(Icons.directions_car_outlined),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(vehicle.plate, style: AppTextStyles.cardTitle),
                        Text(
                          '${vehicle.make} ${vehicle.model} · ${vehicle.year}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: StatusChip(
                      label: docsExpired
                          ? 'Paused: documents expired'
                          : vehicle.status.label,
                      tone: _isPublished && !docsExpired
                          ? StatusTone.active
                          : StatusTone.caution,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text('${Formatters.rwf(vehicle.dailyPrice)} per day'),
              Text(_availability),
              Text(
                nextRental == null
                    ? 'No upcoming rental'
                    : 'Next rental: ${Formatters.dateRange(nextRental!.startDate, nextRental!.endDate)}',
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
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
            ],
          ),
        ),
      ),
    );
  }
}
