import 'package:go_router/go_router.dart';

import 'package:veloce/core/navigation/navigator_keys.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/widgets/placeholder_page.dart';

import 'presentation/pages/public_profile_page.dart';

/// Tab root shown inside the role shell.
GoRoute renterProfileTab() => GoRoute(
  path: RouteNames.renterProfile,
  builder: (context, state) => const PlaceholderPage(
    title: 'Profile',
    route: RouteNames.renterProfile,
    phase: 1,
  ),
);

/// Tab root shown inside the role shell.
GoRoute ownerProfileTab() => GoRoute(
  path: RouteNames.ownerProfile,
  builder: (context, state) => const PlaceholderPage(
    title: 'Profile',
    route: RouteNames.ownerProfile,
    phase: 1,
  ),
);

/// Full-screen routes of the profile feature, opened above the tab bar.
List<RouteBase> profileRoutes() => [
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.profileEdit,
    builder: (context, state) => const PlaceholderPage(
      title: 'Edit profile',
      route: RouteNames.profileEdit,
      phase: 1,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.profileAccounts,
    builder: (context, state) => const PlaceholderPage(
      title: 'Accounts',
      route: RouteNames.profileAccounts,
      phase: 1,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.profileAccountsAdd,
    builder: (context, state) => const PlaceholderPage(
      title: 'Add account',
      route: RouteNames.profileAccountsAdd,
      phase: 1,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.profilePayout,
    builder: (context, state) => const PlaceholderPage(
      title: 'Payout',
      route: RouteNames.profilePayout,
      phase: 1,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.profileLicence,
    builder: (context, state) => const PlaceholderPage(
      title: 'Driving licence',
      route: RouteNames.profileLicence,
      phase: 1,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.profileIdentity,
    builder: (context, state) => const PlaceholderPage(
      title: 'National ID',
      route: RouteNames.profileIdentity,
      phase: 1,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.profileSettings,
    builder: (context, state) => const PlaceholderPage(
      title: 'Settings',
      route: RouteNames.profileSettings,
      phase: 1,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.profileAbout,
    builder: (context, state) => const PlaceholderPage(
      title: 'About',
      route: RouteNames.profileAbout,
      phase: 1,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.profileContact,
    builder: (context, state) => const PlaceholderPage(
      title: 'Contact',
      route: RouteNames.profileContact,
      phase: 1,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.userPattern,
    builder: (context, state) =>
        PublicProfilePage(userId: state.pathParameters['id']!),
  ),
];
