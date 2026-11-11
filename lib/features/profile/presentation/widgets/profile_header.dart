import 'package:flutter/material.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/status_chip.dart';
import 'package:veloce/core/widgets/user_avatar.dart';

/// Photo, name, role label and identity status at the top of the Profile tab.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    required this.name,
    required this.photoUrl,
    required this.roleLabel,
    required this.verified,
    super.key,
  });

  final String name;
  final String? photoUrl;
  final String roleLabel;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        UserAvatar(name: name, photoUrl: photoUrl, radius: 44),
        const SizedBox(height: AppSpacing.md),
        Text(name, style: AppTextStyles.title, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            StatusChip(label: roleLabel, tone: StatusTone.info),
            StatusChip(
              label: verified ? 'Identity verified' : 'Identity not verified',
              tone: verified ? StatusTone.active : StatusTone.caution,
            ),
          ],
        ),
      ],
    );
  }
}
