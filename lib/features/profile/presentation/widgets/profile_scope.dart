import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../bloc/profile_bloc.dart';

/// Provides one [ProfileBloc] (already started) to everything below it.
///
/// Mount it around the Profile tab and, in a `ShellRoute`, around the profile
/// edit, payout, identity and licence routes, so the licence steps
/// (view, change, verify) share one bloc.
class ProfileScope extends StatelessWidget {
  const ProfileScope({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfileBloc>(
      create: (_) => GetIt.instance<ProfileBloc>()..add(const ProfileStarted()),
      child: child,
    );
  }
}
