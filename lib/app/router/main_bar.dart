import 'package:flutter/material.dart';

import 'package:veloce/app/router/shell_action.dart';
import 'package:veloce/app/router/shell_destination.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';

/// The mock's floating bottom bar: a round side button, a pill with the tabs
/// and a round notifications button.
class MainBar extends StatelessWidget {
  const MainBar({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    required this.sideAction,
    required this.onSide,
    required this.onNotifications,
    super.key,
  });

  final List<ShellDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final ShellAction sideAction;
  final VoidCallback onSide;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        child: Row(
          children: [
            _RoundButton(
              icon: sideAction.icon,
              label: sideAction.label,
              onPressed: onSide,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _Pill(
                children: [
                  for (var i = 0; i < destinations.length; i++)
                    Expanded(
                      child: _Tab(
                        destination: destinations[i],
                        selected: i == selectedIndex,
                        onTap: () => onSelected(i),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _RoundButton(
              icon: Icons.notifications_outlined,
              label: 'Notifications',
              onPressed: onNotifications,
            ),
          ],
        ),
      ),
    );
  }
}

const double _tabHeight = 50;

List<BoxShadow> _shadow(AppColors colors) => [
  BoxShadow(
    color: colors.ink.withValues(alpha: 0.16),
    blurRadius: 28,
    offset: const Offset(0, 8),
  ),
];

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        shape: BoxShape.circle,
        boxShadow: _shadow(colors),
      ),
      child: IconButton(
        tooltip: label,
        onPressed: onPressed,
        icon: Icon(icon, color: colors.ink),
        constraints: const BoxConstraints.tightFor(
          width: AppSizes.button,
          height: AppSizes.button,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: _shadow(colors),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Row(children: children),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final ShellDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = selected ? colors.brand : colors.body;
    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      excludeSemantics: true,
      child: Material(
        color: selected ? colors.brandWash : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: _tabHeight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  selected ? destination.selectedIcon : destination.icon,
                  color: color,
                  size: 22,
                ),
                const SizedBox(height: 2),
                Text(
                  destination.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
