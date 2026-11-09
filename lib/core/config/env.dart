/// Typed build-time configuration, supplied with
/// `--dart-define-from-file=env.json`. Documented in `env.example.json`.
final class Env {
  const Env({required this.supabaseUrl, required this.supabaseKey});

  /// Reads the compile-time values and fails fast when one is missing.
  factory Env.fromEnvironment() {
    const url = String.fromEnvironment('SUPABASE_URL');
    const key = String.fromEnvironment('SUPABASE_KEY');
    return Env.validated(supabaseUrl: url, supabaseKey: key);
  }

  factory Env.validated({
    required String supabaseUrl,
    required String supabaseKey,
  }) {
    final missing = [
      if (supabaseUrl.isEmpty) 'SUPABASE_URL',
      if (supabaseKey.isEmpty) 'SUPABASE_KEY',
    ];
    if (missing.isNotEmpty) {
      throw StateError(
        'Missing ${missing.join(', ')}. Copy env.example.json to env.json, '
        'fill it in and run with --dart-define-from-file=env.json.',
      );
    }
    return Env(supabaseUrl: supabaseUrl, supabaseKey: supabaseKey);
  }

  final String supabaseUrl;
  final String supabaseKey;
}
