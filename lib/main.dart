import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'resources/app_colors.dart';
import 'resources/app_metrics.dart';
import 'resources/app_strings.dart';
import 'resources/app_theme.dart';
import 'screens/workspace.dart';
import 'services/class_schedule_store.dart';
import 'services/diag_log.dart';
import 'services/schedule_scope.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 诊断日志：排查版会一直开着，正式版这里不会造成负担（写入很轻）
  await DiagLog.instance.start();

  // 桌面端窗口允许自由缩放，先放开系统层面的方向限制。
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await SystemChrome.setPreferredOrientations(const <DeviceOrientation>[]);
  }

  runApp(const ClarkApp());
}

class ClarkApp extends StatefulWidget {
  const ClarkApp({super.key});

  @override
  State<ClarkApp> createState() => _ClarkAppState();
}

class _ClarkAppState extends State<ClarkApp> {
  ClassScheduleStore? _store;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  /// 读取本地课表。读不出来就多试一次，失败也不让应用卡在启动页。
  Future<void> _bootstrap() async {
    ClassScheduleStore? store;
    for (var attempt = 0; attempt < 2 && store == null; attempt++) {
      try {
        store = await ClassScheduleStore.load();
      } catch (_) {
        store = null;
      }
    }
    if (!mounted) {
      return;
    }
    setState(() => _store = store);
  }

  @override
  Widget build(BuildContext context) {
    final store = _store;
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      scrollBehavior: const _AppScrollBehavior(),
      home: store == null
          ? const _SplashView()
          : ScheduleScope(store: store, child: const WorkspaceShell()),
    );
  }
}

class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.canvas,
      body: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

/// 桌面端也允许鼠标拖动滚动，但不出现拉伸光晕。
class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}

/// 最小窗口尺寸：窗口缩得太小时内容会被挤扁，这里兜住。
const Size kMinWindowSize = Size(720, 560);

/// 桌面端首次打开时的窗口大小建议。
const Size kPreferredWindowSize = Size(1280, 860);

/// 页面统一的水平内边距：窗口宽时留白更多。
double horizontalPaddingOf(BuildContext context) =>
    AppMetrics.pagePadding(MediaQuery.sizeOf(context).width);
