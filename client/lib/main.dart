import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/env.dart';
import 'core/supabase_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!Env.isConfigured) {
    runApp(const EnvMissingApp());
    return;
  }

  await initializeSupabase();

  runApp(
    const ProviderScope(
      child: NineForgeApp(),
    ),
  );
}
