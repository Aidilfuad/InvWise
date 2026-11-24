/// Supabase project configuration.
///
/// Replace the placeholder defaults for local development, or (recommended)
/// pass the real values at build time so they are never committed:
///
///   flutter run \
///     --dart-define=SUPABASE_URL=https://your-project.supabase.co \
///     --dart-define=SUPABASE_PUBLISHABLE_KEY=your-publishable-key
///
/// Never put the service_role key in the app.
class SupabaseConfig {
  const SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://avpgjbhgiuhowsdpwbms.supabase.co',
  );

  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: 'sb_publishable_IMK7UOCKlpNHFJBujykQ8w_C-vVQIAt',
    ),
  );
}