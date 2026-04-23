import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';

import 'routing/router.dart';

class NineForgeApp extends StatelessWidget {
  const NineForgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MacosApp.router(
      title: 'Nine Forge',
      theme: MacosThemeData.light(),
      darkTheme: MacosThemeData.dark(),
routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}

class EnvMissingApp extends StatelessWidget {
  const EnvMissingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MacosApp(
      title: 'Nine Forge',
      theme: MacosThemeData.light(),
      darkTheme: MacosThemeData.dark(),
debugShowCheckedModeBanner: false,
      home: MacosWindow(
        child: MacosScaffold(
          toolBar: const ToolBar(title: Text('Nine Forge')),
          children: [
            ContentArea(
              builder: (context, scrollController) => Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        MacosIcon(
                          CupertinoIcons.exclamationmark_triangle_fill,
                          size: 48,
                          color: MacosColor.fromRGBO(255, 149, 0, 1),
                        ),
                        SizedBox(height: 12),
                        Text(
                          '환경변수가 주입되지 않았습니다.',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 12),
                        Text(
                          '빌드 시 --dart-define-from-file=.env.dart-define.json '
                          '옵션을 붙여주세요.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
