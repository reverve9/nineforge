import 'package:supabase_flutter/supabase_flutter.dart';

import 'env.dart';

/// Initialize Supabase SDK. Must be called once before `runApp` and only
/// when [Env.isConfigured] is true (guarded in `main.dart`).
Future<void> initializeSupabase() async {
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );
}

SupabaseClient get supabase => Supabase.instance.client;
