import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/data/services/in_flight_requests.dart';

void main() {
  test('a request completes and returns its value', () async {
    final requests = InFlightRequests<int>();

    expect(await requests.run('a', () async => 1), 1);
  });

  test('concurrent callers for one key share a single request', () async {
    final requests = InFlightRequests<int>();
    final gate = Completer<int>();
    var started = 0;
    Future<int> start() {
      started++;
      return gate.future;
    }

    final first = requests.run('a', start);
    final second = requests.run('a', start);
    gate.complete(7);

    expect(await first, 7);
    expect(await second, 7);
    expect(started, 1);
  });

  test('a settled key starts a new request next time', () async {
    final requests = InFlightRequests<int>();
    var started = 0;
    Future<int> start() async => ++started;

    expect(await requests.run('a', start), 1);
    expect(await requests.run('a', start), 2);
  });

  test('different keys do not share', () async {
    final requests = InFlightRequests<String>();

    final a = requests.run('a', () async => 'A');
    final b = requests.run('b', () async => 'B');

    expect([await a, await b], ['A', 'B']);
  });

  test('a failed request reaches every caller and is not remembered', () async {
    final requests = InFlightRequests<int>();
    final gate = Completer<int>();

    final first = requests.run('a', () => gate.future);
    final second = requests.run('a', () => gate.future);
    gate.completeError(StateError('offline'));

    await expectLater(first, throwsStateError);
    await expectLater(second, throwsStateError);
    expect(await requests.run('a', () async => 3), 3);
  });
}
