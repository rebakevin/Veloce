import 'dart:async';

import 'package:flutter/foundation.dart';

/// Makes the router re-run its redirect whenever [stream] emits.
class RouterRefreshListenable extends ChangeNotifier {
  RouterRefreshListenable(Stream<void> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<void> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
