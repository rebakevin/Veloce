import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/expiry_sweeper_cubit.dart';

/// Sweeps lazy expiries again whenever the app returns to the foreground.
class BookingExpiryObserver extends StatefulWidget {
  const BookingExpiryObserver({required this.child, super.key});

  final Widget child;

  @override
  State<BookingExpiryObserver> createState() => _BookingExpiryObserverState();
}

class _BookingExpiryObserverState extends State<BookingExpiryObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<ExpirySweeperCubit>().sweep();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
