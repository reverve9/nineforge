/// Read-only wrapper around `--dart-define-from-file` injected values.
///
/// Builds must pass `--dart-define-from-file=.env.dart-define.json`;
/// at runtime, empty strings signal a missing config and the UI shows
/// an env-error page instead of attempting Supabase init.
class Env {
  Env._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
