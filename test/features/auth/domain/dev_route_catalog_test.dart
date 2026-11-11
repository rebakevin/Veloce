import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/features/auth/domain/dev_route_catalog.dart';

void main() {
  DevRouteEntry entryFor(String pattern) =>
      DevRouteCatalog.fromPatterns([pattern]).single;

  test('booking, car and user parameters use seeded ids', () {
    expect(
      entryFor(RouteNames.bookingPayPattern).path,
      '/booking/booking-confirmed/pay',
    );
    expect(entryFor(RouteNames.carMediaPattern).path, '/car/car-1/media');
    expect(entryFor(RouteNames.userPattern).path, '/user/renter1');
    expect(
      entryFor(RouteNames.ownerCarTransactionsPattern).path,
      '/owner/finances/car/car-1/transactions',
    );
  });

  test('owner and renter paths carry the role the router requires', () {
    expect(entryFor(RouteNames.ownerCars).role, UserRole.owner);
    expect(entryFor(RouteNames.renterHome).role, UserRole.renter);
    expect(entryFor(RouteNames.bookingPattern).role, isNull);
  });

  test('dev tools are left out, duplicates collapse, result is sorted', () {
    final entries = DevRouteCatalog.fromPatterns([
      RouteNames.renterHome,
      RouteNames.devLogin,
      RouteNames.devRoutes,
      RouteNames.renterHome,
      RouteNames.login,
    ]);
    expect(entries.map((entry) => entry.pattern), [
      RouteNames.login,
      RouteNames.renterHome,
    ]);
  });
}
