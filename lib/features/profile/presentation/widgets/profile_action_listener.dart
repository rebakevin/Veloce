import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:veloce/core/widgets/app_messenger.dart';

import '../bloc/profile_bloc.dart';

/// Reacts once to a successful [kind] action: success message, back to the
/// previous screen, then [ProfileActionAcknowledged].
class ProfileActionListener extends StatelessWidget {
  const ProfileActionListener({
    required this.kind,
    required this.successMessage,
    required this.child,
    super.key,
  });

  final ProfileActionKind kind;
  final String successMessage;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileBloc, ProfileState>(
      listenWhen: (previous, current) =>
          current is ProfileLoaded &&
          current.action.kind == kind &&
          current.action.status == ProfileActionStatus.success &&
          !(previous is ProfileLoaded && previous.action == current.action),
      listener: (context, state) {
        GetIt.instance<AppMessenger>().success(successMessage);
        context.read<ProfileBloc>().add(const ProfileActionAcknowledged());
        if (context.canPop()) context.pop();
      },
      child: child,
    );
  }
}
