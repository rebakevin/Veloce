import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:veloce/core/data/services/preferences_service.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';

import '../widgets/brand_mark.dart';
import '../widgets/google_sign_up_button.dart';
import '../widgets/onboarding_slide.dart';
import '../widgets/page_index_cubit.dart';

/// Onboarding slides, ending on the Create account / Log in choice. Marks
/// `onboarding_seen` when the last slide is reached or the slides are skipped.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PageIndexCubit(),
      child: WelcomeView(
        markOnboardingSeen:
            GetIt.instance<PreferencesService>().markOnboardingSeen,
      ),
    );
  }
}

class WelcomeView extends StatefulWidget {
  const WelcomeView({required this.markOnboardingSeen, super.key});

  final Future<void> Function() markOnboardingSeen;

  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView> {
  static const Duration _slideDuration = Duration(milliseconds: 300);
  final PageController _controller = PageController();

  int get _last => onboardingSlides.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    context.read<PageIndexCubit>().select(index);
    if (index == _last) widget.markOnboardingSeen();
  }

  void _open(String route) {
    widget.markOnboardingSeen();
    context.push(route);
  }

  void _skip() => _controller.animateToPage(
    _last,
    duration: _slideDuration,
    curve: Curves.easeOut,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.gutter,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  const BrandMark(),
                  const Spacer(),
                  BlocBuilder<PageIndexCubit, int>(
                    builder: (context, index) => index == _last
                        ? const SizedBox(height: AppSizes.iconControl)
                        : TextButton(
                            onPressed: _skip,
                            child: const Text('Skip'),
                          ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: _onPageChanged,
                children: [
                  for (final slide in onboardingSlides)
                    OnboardingSlide(data: slide),
                ],
              ),
            ),
            const _Dots(),
            _WelcomeActions(
              onCreateAccount: () => _open(RouteNames.registerRole),
              onLogin: () => _open(RouteNames.login),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return BlocBuilder<PageIndexCubit, int>(
      builder: (context, index) => Semantics(
        label: 'Slide ${index + 1} of ${onboardingSlides.length}',
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < onboardingSlides.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(AppSpacing.xs),
                width: i == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == index ? colors.brand : colors.line,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeActions extends StatelessWidget {
  const _WelcomeActions({required this.onCreateAccount, required this.onLogin});

  final VoidCallback onCreateAccount;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      child: Column(
        children: [
          FilledButton(
            onPressed: onCreateAccount,
            child: const Text('Create an account'),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(onPressed: onLogin, child: const Text('Log in')),
          const SizedBox(height: AppSpacing.md),
          const GoogleSignUpButton(label: 'Continue with Google'),
        ],
      ),
    );
  }
}
