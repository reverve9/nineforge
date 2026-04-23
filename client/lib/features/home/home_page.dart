import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import 'providers/healthcheck_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncResult = ref.watch(healthcheckProvider);

    return MacosWindow(
      child: MacosScaffold(
        toolBar: const ToolBar(
          title: Text('Nine Forge'),
          titleWidth: 160,
        ),
        children: [
          ContentArea(
            builder: (context, _) => Center(
              child: asyncResult.when(
                loading: () => const _HealthcheckLoading(),
                error: (e, st) => _HealthcheckFailure(
                  message: e.toString(),
                  stack: st.toString(),
                ),
                data: (r) => switch (r) {
                  HealthcheckOk(:final count) => _HealthcheckSuccess(count: count),
                  HealthcheckError(:final message, :final stack) =>
                    _HealthcheckFailure(message: message, stack: stack),
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthcheckLoading extends StatelessWidget {
  const _HealthcheckLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        ProgressCircle(),
        SizedBox(height: 16),
        Text('Checking connection...'),
      ],
    );
  }
}

class _HealthcheckSuccess extends StatelessWidget {
  final int count;
  const _HealthcheckSuccess({required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const MacosIcon(
          CupertinoIcons.checkmark_circle_fill,
          size: 48,
          color: MacosColor.fromRGBO(52, 199, 89, 1),
        ),
        const SizedBox(height: 12),
        const Text(
          'Connected to Supabase',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text('dim_source: $count rows'),
      ],
    );
  }
}

class _HealthcheckFailure extends StatefulWidget {
  final String message;
  final String stack;
  const _HealthcheckFailure({required this.message, required this.stack});

  @override
  State<_HealthcheckFailure> createState() => _HealthcheckFailureState();
}

class _HealthcheckFailureState extends State<_HealthcheckFailure> {
  bool _showStack = false;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MacosIcon(
              CupertinoIcons.xmark_circle_fill,
              size: 48,
              color: MacosColor.fromRGBO(255, 59, 48, 1),
            ),
            const SizedBox(height: 12),
            const Text(
              'Connection failed',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              widget.message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            PushButton(
              controlSize: ControlSize.small,
              secondary: true,
              onPressed: () => setState(() => _showStack = !_showStack),
              child: Text(_showStack ? 'Hide stack' : 'Show stack'),
            ),
            if (_showStack) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: MacosColors.quaternaryLabelColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.stack,
                  style: const TextStyle(
                    fontFamily: 'Menlo',
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
