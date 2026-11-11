import 'package:flutter/material.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/widgets/status_chip.dart';
import 'package:veloce/core/widgets/user_avatar.dart';
import 'package:veloce/features/auth/auth.dart';

/// One linked account: avatar, name, email, role label and a "Current" mark.
class AccountTile extends StatelessWidget {
  const AccountTile({
    required this.account,
    required this.isCurrent,
    required this.enabled,
    required this.onSwitch,
    required this.onRemove,
    super.key,
  });

  final LinkedAccount account;
  final bool isCurrent;
  final bool enabled;
  final VoidCallback onSwitch;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: enabled,
      minTileHeight: AppSizes.listRow,
      leading: UserAvatar(name: account.name),
      title: Text(account.name),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs),
        child: Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(account.email),
            StatusChip(label: account.role.label, tone: StatusTone.info),
            if (isCurrent)
              const StatusChip(label: 'Current', tone: StatusTone.active),
          ],
        ),
      ),
      trailing: IconButton(
        tooltip: 'Remove ${account.name} from this device',
        onPressed: enabled ? onRemove : null,
        icon: const Icon(Icons.delete_outline),
      ),
      onTap: isCurrent ? null : onSwitch,
    );
  }
}
