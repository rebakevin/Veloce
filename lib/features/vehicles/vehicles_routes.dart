import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:veloce/core/navigation/navigator_keys.dart';
import 'package:veloce/core/navigation/route_names.dart';

import 'presentation/bloc/availability_bloc.dart';
import 'presentation/bloc/car_wizard_bloc.dart';
import 'presentation/bloc/documents_bloc.dart';
import 'presentation/bloc/my_cars_bloc.dart';
import 'presentation/pages/availability_page.dart';
import 'presentation/pages/car_published_page.dart';
import 'presentation/pages/car_wizard_page.dart';
import 'presentation/pages/documents_page.dart';
import 'presentation/pages/my_cars_page.dart';

/// Full-screen routes of the vehicles feature, opened above the tab bar.
List<RouteBase> vehiclesRoutes() => [
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.ownerCars,
    builder: (context, state) => BlocProvider(
      create: (_) => GetIt.I<MyCarsBloc>()..add(const MyCarsStarted()),
      child: const MyCarsPage(),
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.ownerCarNew,
    builder: (context, state) => BlocProvider(
      create: (_) => GetIt.I<CarWizardBloc>(),
      child: const CarWizardPage(),
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.ownerCarPublishedPattern,
    builder: (context, state) =>
        CarPublishedPage(vehicleId: state.pathParameters['id']!),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.ownerCarEditPattern,
    builder: (context, state) {
      final id = state.pathParameters['id']!;
      return BlocProvider(
        create: (_) => GetIt.I<CarWizardBloc>()..add(WizardEditStarted(id)),
        child: CarWizardPage(editVehicleId: id),
      );
    },
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.ownerCarAvailabilityPattern,
    builder: (context, state) {
      final id = state.pathParameters['id']!;
      return BlocProvider(
        create: (_) =>
            GetIt.I<AvailabilityBloc>()..add(AvailabilityStarted(id)),
        child: AvailabilityPage(vehicleId: id),
      );
    },
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.ownerCarDocumentsPattern,
    builder: (context, state) {
      final id = state.pathParameters['id']!;
      return BlocProvider(
        create: (_) => GetIt.I<DocumentsBloc>()..add(DocumentsStarted(id)),
        child: DocumentsPage(vehicleId: id),
      );
    },
  ),
];
