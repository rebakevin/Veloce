import 'package:flutter/material.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';

/// One tappable row of the Profile tab.
class ProfileLinkTile extends StatelessWidget {
  const ProfileLinkTile({
    required this.icon,
    required this.title,
    required this.onTap,
    super.key,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;
    return ListTile(
      minTileHeight: AppSizes.iconControl,
      leading: Icon(icon, color: context.colors.brand),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

/// Rows in one rounded card, separated by dividers.
class ProfileLinkGroup extends StatelessWidget {
  const ProfileLinkGroup({required this.tiles, super.key});

  final List<ProfileLinkTile> tiles;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var index = 0; index < tiles.length; index++) ...[
            if (index > 0) const Divider(height: 1),
            tiles[index],
          ],
        ],
      ),
    );
  }
}
