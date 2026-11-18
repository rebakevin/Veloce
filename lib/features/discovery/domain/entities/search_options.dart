import 'package:veloce/core/domain/enums/vehicle_type.dart';

/// Lists shared by the home search card, the search page and the filters page.
abstract final class SearchOptions {
  static const String anywhere = 'Anywhere in Kigali';

  /// Every neighbourhood present in the base seed and the Phase 3 scenario.
  static const List<String> neighbourhoods = [
    'Kacyiru',
    'Nyarutarama',
    'Kimironko',
    'Remera',
    'Kicukiro',
    'Nyamirambo',
    'Gisozi',
    'Kimihurura',
    'Kibagabaga',
    'Kabeza',
  ];

  static const List<VehicleType> homeTypes = [
    VehicleType.sedan,
    VehicleType.suv,
    VehicleType.hatchback,
  ];

  static const List<int> seatOptions = [5, 7];
}
