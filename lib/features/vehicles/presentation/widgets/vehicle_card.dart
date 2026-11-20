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
    required this.onToggleStatus,
    required this.onRemove,
    this.nextRental,
    super.key,
  });

  final Vehicle vehicle;
  final Booking? nextRental;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onAvailability;
  final VoidCallback onToggleStatus;
  final VoidCallback onRemove;

  bool get _isPublished => vehicle.status == VehicleStatus.published;

  String get _availability {
    final from = vehicle.availableFrom;
    final to = vehicle.availableTo;
    if (from == null || to == null) return 'No dates set';
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
                  StatusChip(
                    label: vehicle.status.label,
                    tone: _isPublished ? StatusTone.active : StatusTone.caution,
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
