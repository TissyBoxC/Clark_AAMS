import 'package:clark_aams/models/course.dart';
import 'package:clark_aams/resources/app_theme.dart';
import 'package:clark_aams/screens/course_settings_page.dart';
import 'package:clark_aams/screens/term_setup_page.dart';
import 'package:clark_aams/services/class_schedule_store.dart';
import 'package:clark_aams/services/schedule_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 这些测试走真实 Navigator.push，而不是直接把页面当 home 塞进测试树。
///
/// 之前的测试直接把页面放在 ScheduleScope 下面，所以没能发现真正的缺陷：
/// 应用里 Scope 挂在 home 内部，Navigator 推出的新路由读不到它，
/// 一进课程设置就是灰屏。
const _phone = Size(390, 844);

Future<ClassScheduleStore> _store(WidgetTester tester) async {
  late ClassScheduleStore store;
  await tester.runAsync(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    store = await ClassScheduleStore.load();
    await store.addCourse(
      const Course(
        id: 1,
        name: '高等数学',
        startWeek: 1,
        endWeek: 16,
        dayOfWeek: 1,
        startLesson: 1,
        endLesson: 2,
        location: 'A101',
        teacher: '张三',
        weekPattern: WeekPattern(ranges: [WeekRange(1, 16)]),
      ),
    );
  });
  return store;
}

/// 复刻 main.dart 修复前的挂载方式：Scope 放在 home 里面。
///
/// 这个结构是灰屏的根因——Navigator 推出的新路由不是 home 的子节点，
/// 读不到 Scope，一进课程设置就抛异常。
Widget _appLegacyMount(ClassScheduleStore store) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: ScheduleScope(
      store: store,
      child: Builder(
        builder: (context) => Scaffold(
          body: Column(
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CourseSettingsPage(),
                  ),
                ),
                child: const Text('打开课程设置'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    fullscreenDialog: true,
                    builder: (_) => TermSetupPage(
                      initialStartTimes: const [],
                      initialTermStartDate: DateTime(2026, 9, 1),
                      lessonCount: 12,
                      profiles: const [],
                      notice: '',
                    ),
                  ),
                ),
                child: const Text('打开学期设置'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// 复刻 main.dart 修复后的挂载方式：Scope 包在 MaterialApp 外层。
Widget _app(ClassScheduleStore store) {
  return ScheduleScope(
    store: store,
    child: MaterialApp(
      theme: AppTheme.light(),
      home: Builder(
        builder: (context) => Scaffold(
          body: Column(
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CourseSettingsPage(),
                  ),
                ),
                child: const Text('打开课程设置'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    fullscreenDialog: true,
                    builder: (_) => TermSetupPage(
                      initialStartTimes: const [],
                      initialTermStartDate: DateTime(2026, 9, 1),
                      lessonCount: 12,
                      profiles: const [],
                      notice: '',
                    ),
                  ),
                ),
                child: const Text('打开学期设置'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('旧挂载方式确实会灰屏（守住根因，防止改回去）', (tester) async {
    tester.view.physicalSize = _phone;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final store = await _store(tester);
    await tester.pumpWidget(_appLegacyMount(store));
    await tester.pump();

    await tester.tap(find.text('打开课程设置'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Scope 在 home 内部时，推出的路由读不到它，必然抛异常。
    // 这条断言一旦失败，说明挂载结构变了，下面两条"不灰屏"就不再成立。
    expect(
      tester.takeException(),
      isNotNull,
      reason: 'Scope 放回 home 内部时应当复现灰屏；若此处通过，说明该结构的风险已变化',
    );
  }, timeout: const Timeout(Duration(seconds: 40)));

  testWidgets('从别处推出课程设置页，不会灰屏', (tester) async {
    tester.view.physicalSize = _phone;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final store = await _store(tester);
    await tester.pumpWidget(_app(store));
    await tester.pump();

    await tester.tap(find.text('打开课程设置'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull, reason: '课程设置页无法在 Navigator 路由里渲染');
    expect(find.text('高等数学'), findsWidgets);
  }, timeout: const Timeout(Duration(seconds: 40)));

  testWidgets('从别处推出学期设置页，不会灰屏', (tester) async {
    tester.view.physicalSize = _phone;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final store = await _store(tester);
    await tester.pumpWidget(_app(store));
    await tester.pump();

    await tester.tap(find.text('打开学期设置'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull, reason: '学期设置页无法在 Navigator 路由里渲染');
  }, timeout: const Timeout(Duration(seconds: 40)));

  testWidgets('课程设置页里能新建课程', (tester) async {
    tester.view.physicalSize = _phone;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final store = await _store(tester);
    await tester.pumpWidget(
      ScheduleScope(
        store: store,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const CourseSettingsPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // 添加课程入口应当在课程设置页，而不是课表页。
    expect(find.text('添加课程'), findsWidgets);
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(seconds: 40)));
}
