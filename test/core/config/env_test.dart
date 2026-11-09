import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/config/env.dart';

void main() {
  test('valid values build an Env', () {
    final env = Env.validated(
      supabaseUrl: 'https://x.supabase.co',
      supabaseKey: 'key',
    );
    expect(env.supabaseUrl, 'https://x.supabase.co');
  });

  test('missing values fail fast and name every missing key', () {
    expect(
      () => Env.validated(supabaseUrl: '', supabaseKey: ''),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          allOf(contains('SUPABASE_URL'), contains('SUPABASE_KEY')),
        ),
      ),
    );
  });
}
