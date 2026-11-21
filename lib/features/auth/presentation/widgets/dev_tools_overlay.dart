import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:veloce/core/data/services/momo_gateway_sim.dart';
import 'package:veloce/core/data/services/verification_sim.dart';
import 'package:veloce/core/navigation/navigator_keys.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/widgets/app_messenger.dart';

import '../../data/dev_sign_in.dart';
import '../bloc/dev_tools_cubit.dart';
import 'dev_tools_sheet.dart';

/// Wraps the whole app with the floating dev button, so it is on every page.
/// Debug builds only: in any other build it returns [child] untouched. Drag the
/// button out of the way; a tap opens [DevToolsSheet].
class DevToolsOverlay extends StatefulWidget {
  const DevToolsOverlay({required this.router, required this.child, super.key});

  final GoRouter router;
  final Widget child;

  @override
  State<DevToolsOverlay> createState() => _DevToolsOverlayState();
}

class _DevToolsOverlayState extends State<DevToolsOverlay> {
  static const double _size = 44;
  static const double _margin = 16;
  static const double _aboveTabBar = 120;

  /// Top-left corner of the button; null until the first layout places it.
  final ValueNotifier<Offset?> _position = ValueNotifier(null);

  /// The button steps aside while the panel is open, so it never covers it.
  final ValueNotifier<bool> _panelOpen = ValueNotifier(false);

  /// Owned here, not by the panel: a sign-in starts as the panel closes, and
  /// the switches must keep their value between openings.
  late final DevToolsCubit _cubit = DevToolsCubit(
    signIn: GetIt.instance<DevSignIn>(),
    momo: GetIt.instance<MomoGatewaySim>(),
    verification: GetIt.instance<VerificationSim>(),
  );

  @override
  void dispose() {
    _position.dispose();
    _panelOpen.dispose();
    _cubit.close();
    super.dispose();
  }

  void _onState(BuildContext context, DevToolsState state) {
    switch (state.status) {
      case DevToolsStatus.signedIn:
        // The router redirect moves a signed-in user from the splash to Home.
        widget.router.go(RouteNames.splash);
      case DevToolsStatus.failed:
        GetIt.instance<AppMessenger>().error(
          state.message ?? 'Sign-in failed.',
        );
      case DevToolsStatus.idle || DevToolsStatus.signingIn:
        break;
    }
  }

  void _open() {
    // The overlay sits above the router's navigator, so the sheet opens on the
    // root navigator's own context.
    final navigatorContext = rootNavigatorKey.currentContext;
    if (navigatorContext == null) return;
    _panelOpen.value = true;
    showModalBottomSheet<void>(
      context: navigatorContext,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => BlocProvider.value(
        value: _cubit,
        child: DevToolsSheet(router: widget.router),
      ),
    ).whenComplete(() => _panelOpen.value = false);
  }

  Offset _clamp(Offset position, Size area) => Offset(
    position.dx.clamp(_margin, area.width - _size - _margin),
    position.dy.clamp(_margin, area.height - _size - _margin),
  );

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return widget.child;
    return BlocListener<DevToolsCubit, DevToolsState>(
      bloc: _cubit,
      listener: _onState,
      child: Stack(
        children: [
          widget.child,
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) => ValueListenableBuilder<bool>(
                valueListenable: _panelOpen,
                builder: (context, open, _) => open
                    ? const SizedBox.shrink()
                    : ValueListenableBuilder<Offset?>(
                        valueListenable: _position,
                        builder: (context, position, _) => _buildButton(
                          context,
                          position,
                          constraints.biggest,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(BuildContext context, Offset? position, Size area) {
    final colors = Theme.of(context).colorScheme;
    final at = _clamp(
      position ??
          Offset(
            area.width - _size - _margin,
            area.height - _size - _aboveTabBar,
          ),
      area,
    );
    return Stack(
      children: [
        Positioned(
          left: at.dx,
          top: at.dy,
          child: GestureDetector(
            onPanUpdate: (details) =>
                _position.value = _clamp(at + details.delta, area),
            child: Semantics(
              button: true,
              label: 'Dev tools',
              child: Material(
                color: colors.primaryContainer,
                elevation: 4,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _open,
                  child: SizedBox.square(
                    dimension: _size,
                    child: Icon(
                      Icons.developer_mode,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
