import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_provider.dart';

part 'healthcheck_provider.g.dart';

sealed class HealthcheckResult {
  const HealthcheckResult();
  const factory HealthcheckResult.ok({required int count}) = HealthcheckOk;
  const factory HealthcheckResult.error({
    required String message,
    required String stack,
  }) = HealthcheckError;
}

final class HealthcheckOk extends HealthcheckResult {
  final int count;
  const HealthcheckOk({required this.count});
}

final class HealthcheckError extends HealthcheckResult {
  final String message;
  final String stack;
  const HealthcheckError({required this.message, required this.stack});
}

@riverpod
Future<HealthcheckResult> healthcheck(Ref ref) async {
  final client = ref.watch(supabaseClientProvider);
  try {
    final count = await client.from('dim_source').count(CountOption.exact);
    return HealthcheckResult.ok(count: count);
  } catch (e, st) {
    return HealthcheckResult.error(
      message: e.toString(),
      stack: st.toString(),
    );
  }
}
