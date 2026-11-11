import 'package:go_router/go_router.dart';

import 'package:veloce/core/navigation/navigator_keys.dart';
import 'package:veloce/core/navigation/route_names.dart';

import 'presentation/pages/about_page.dart';
import 'presentation/pages/accounts_page.dart';
import 'presentation/pages/add_account_page.dart';
import 'presentation/pages/contact_page.dart';
import 'presentation/pages/edit_profile_page.dart';
import 'presentation/pages/identity_page.dart';
import 'presentation/pages/licence_change_page.dart';
import 'presentation/pages/licence_page.dart';
import 'presentation/pages/licence_verify_page.dart';
import 'presentation/pages/payout_page.dart';
import 'presentation/pages/profile_tab_page.dart';
import 'presentation/pages/public_profile_page.dart';
import 'presentation/pages/settings_page.dart';
import 'presentation/widgets/profile_scope.dart';

/// Tab root shown inside the role shell.
GoRoute renterProfileTab() => GoRoute(
  path: RouteNames.renterProfile,
  builder: (context, state) => const ProfileScope(child: ProfileTabPage()),
);

/// Tab root shown inside the role shell.
GoRoute ownerProfileTab() => GoRoute(
  path: RouteNames.ownerProfile,
  builder: (context, state) => const ProfileScope(child: ProfileTabPage()),
);

/// Full-screen routes of the profile feature, opened above the tab bar.
List<RouteBase> profileRoutes() => [
  // One ProfileBloc for the screens that read or edit the user's own data.
  ShellRoute(
    parentNavigatorKey: rootNavigatorKey,
    builder: (context, state, child) => ProfileScope(child: child),
    routes: [
      GoRoute(
        path: RouteNames.profileEdit,
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        path: RouteNames.profilePayout,
        builder: (context, state) => const PayoutPage(),
      ),
      GoRoute(
        path: RouteNames.profileIdentity,
        builder: (context, state) => const IdentityPage(),
      ),
      GoRoute(
        path: RouteNames.profileLicence,
        builder: (context, state) => const LicencePage(),
      ),
      GoRoute(
        path: RouteNames.profileLicenceChange,
        builder: (context, state) => const LicenceChangePage(),
      ),
      GoRoute(
        path: RouteNames.profileLicenceVerify,
        builder: (context, state) => const LicenceVerifyPage(),
      ),
    ],
  ),
  // Pages that build their own bloc or cubit.
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.profileAccounts,
    builder: (context, state) => const AccountsPage(),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.profileAccountsAdd,
    builder: (context, state) => const AddAccountPage(),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.profileSettings,
    builder: (context, state) => const SettingsPage(),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.profileAbout,
    builder: (context, state) => const AboutPage(),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.profileContact,
    builder: (context, state) => const ContactPage(),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.userPattern,
    builder: (context, state) =>
        PublicProfilePage(userId: state.pathParameters['id']!),
  ),
];
