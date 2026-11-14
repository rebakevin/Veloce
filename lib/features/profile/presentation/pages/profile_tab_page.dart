import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:veloce/core/domain/enums/auth_provider_kind.dart';
import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/layout/responsive.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/widgets/section_header.dart';
import 'package:veloce/features/auth/auth.dart';

import '../bloc/profile_bloc.dart';
import '../widgets/contact_details_card.dart';
import '../widgets/delete_account_dialog.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_link_tile.dart';
import '../widgets/profile_loaded_builder.dart';

/// Profile tab of both roles. Needs a [ProfileBloc] (see `ProfileScope`) and
/// the app-wide [AuthBloc] above it.
class ProfileTabPage extends StatelessWidget {
  const ProfileTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ProfileLoadedBuilder(
        builder: (context, state) => _ProfileContent(state: state),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.state});

  final ProfileLoaded state;

  @override
  Widget build(BuildContext context) {
    final account = state.account;
    final isOwner = account.role == UserRole.owner;
    return ListView(
      padding: Responsive.pagePadding(context)
          .copyWith(top: AppSpacing.lg, bottom: AppSpacing.xl),
      children: [
        ProfileHeader(
          name: account.name,
          photoUrl: account.photoUrl,
          roleLabel: account.role.label,
          verified: account.verified,
        ),
        const SizedBox(height: AppSpacing.xl),
        ContactDetailsCard(
          phone: state.contact.phone,
          email: state.contact.email,
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Account'),
        ProfileLinkGroup(
          tiles: [
            ProfileLinkTile(
              icon: Icons.edit_outlined,
              title: 'Edit profile',
              onTap: () => _open(context, RouteNames.profileEdit),
            ),
            ProfileLinkTile(
              icon: Icons.switch_account_outlined,
              title: 'Switch account',
              onTap: () => _open(context, RouteNames.profileAccounts),
            ),
            if (isOwner) ...[
              ProfileLinkTile(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Payment method',
                subtitle: _payoutLabel(state),
                onTap: () => _open(context, RouteNames.profilePayout),
              ),
              ProfileLinkTile(
                icon: Icons.badge_outlined,
                title: 'National ID',
                subtitle: state.identity == null ? 'Not added' : 'Saved',
                onTap: () => _open(context, RouteNames.profileIdentity),
              ),
            ] else ...[
              ProfileLinkTile(
                icon: Icons.receipt_long_outlined,
                title: 'Payment history',
                onTap: () => _open(context, RouteNames.renterPayments),
              ),
              ProfileLinkTile(
                icon: Icons.credit_card_outlined,
                title: 'Driving licence',
                subtitle: _licenceLabel(state),
                onTap: () => _open(context, RouteNames.profileLicence),
              ),
            ],
            ProfileLinkTile(
              icon: Icons.star_outline,
              title: 'Reviews',
              onTap: () => _open(context, RouteNames.profileReviews),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'App'),
        ProfileLinkGroup(
          tiles: [
            ProfileLinkTile(
              icon: Icons.settings_outlined,
              title: 'Settings',
              onTap: () => _open(context, RouteNames.profileSettings),
            ),
            ProfileLinkTile(
              icon: Icons.info_outline,
              title: 'About Veloce',
              onTap: () => _open(context, RouteNames.profileAbout),
            ),
            ProfileLinkTile(
              icon: Icons.support_agent_outlined,
              title: 'Contact support',
              onTap: () => _open(context, RouteNames.profileContact),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        OutlinedButton.icon(
          onPressed: () => _confirmSignOut(context),
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton.icon(
          onPressed: () => showDeleteAccountDialog(
            context,
            needsPassword:
                state.contact.authProvider == AuthProviderKind.password,
          ),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          icon: const Icon(Icons.delete_forever_outlined),
          label: const Text('Delete account'),
        ),
      ],
    );
  }

  static String _payoutLabel(ProfileLoaded state) {
    final number = state.payout?.momoNumber;
    return number == null ? 'Not set' : '0$number';
  }

  static String _licenceLabel(ProfileLoaded state) {
    final licence = state.licence;
    if (licence == null) return 'Not added';
    return licence.active ? 'Active' : 'Inactive';
  }

  /// Opens [route] above the tab bar and reloads when the user comes back, so
  /// edits made on the other screens show here.
  static Future<void> _open(BuildContext context, String route) async {
    final bloc = context.read<ProfileBloc>();
    await context.push<void>(route);
    if (!bloc.isClosed) bloc.add(const ProfileStarted());
  }

  static Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'Your linked accounts stay on this device, so you can switch back.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    context.read<AuthBloc>().add(const SignOutRequested());
  }
}
