import 'dart:async';

/// Shares one running request per key: callers that ask for a key while its
/// request is still pending get the same future instead of starting another.
class InFlightRequests<T> {
  final Map<String, Future<T>> _pending = {};

  Future<T> run(String key, Future<T> Function() start) {
    final existing = _pending[key];
    if (existing != null) return existing;
    final request = start();
    _pending[key] = request;
    // Forget the key once settled. The callback must not return the future it
    // removes: `whenComplete` would wait on it and never finish.
    unawaited(
      request.then<void>(
        (_) {
          _pending.remove(key);
        },
        onError: (Object _) {
          _pending.remove(key);
        },
      ),
    );
    return request;
  }
}
