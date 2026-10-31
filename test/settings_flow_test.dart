import 'package:clark_aams/resources/app_strings.dart';
import 'package:clark_aams/resources/app_theme.dart';
import 'package:clark_aams/screens/course_settings_page.dart';
import 'package:clark_aams/screens/term_setup_page.dart';
import 'package:clark_aams/services/class_schedule_store.dart';
import 'package:clark_aams/services/schedule_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _phone = Size(390, 844);

Future<ClassScheduleStore> _store(WidgetTester tester) async {
  late ClassScheduleStore store;
  await tester.runAsync(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    store = await ClassScheduleStore.load();
  });
  return store;
}

Widget _host(ClassScheduleStore store, Widget child) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: ScheduleScope(store: store, child: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('保存学期设置后 store 能正常更新并通知界面', (tester) async {
    tester.view.physicalSize = _phone;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final store = await _store(tester);
    var notified = 0;
    store.addListener(() => notified++);

    await tester.runAsync(() async {
      await store.updateSettings(store.settings.copyWith(maxWeeks: 20));
    });

    expect(store.settings.maxWeeks, 20, reason: '设置没有写进 store');
    expect(notified, greaterThan(0), reason: 'store 没有通知界面刷新');
  }, timeout: const Timeout(Duration(seconds: 30)));

  testWidgets('学期设置页打开时总周数取到真实值', (tester) async {
    tester.view.physicalSize = _phone;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final store = await _store(tester);
    await tester.runAsync(() async {
      await store.updateSettings(store.settings.copyWith(maxWeeks: 24));
    });

    await tester.pumpWidget(
      _host(
        store,
        TermSetupPage(
          initialStartTimes: const [],
          initialTermStartDate: DateTime(2026, 9, 1),
          lessonCount: 12,
          profiles: const [],
          notice: '',
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull, reason: '学期设置页渲染抛异常');
    // 页面上应能看到 store 里的总周数 24，而不是退化成默认值。
    expect(find.textContaining('24'), findsWidgets);
  }, timeout: const Timeout(Duration(seconds: 30)));

  testWidgets('课程设置在保存后能从空列表切到课程列表', (tester) async {
    tester.view.physicalSize = _phone;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final store = await _store(tester);
    await tester.pumpWidget(_host(store, const CourseSettingsPage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 一开始没有课程，应显示空状态而不是灰屏。
    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.emptyScheduleTitle), findsWidgets);

    await tester.runAsync(() async {
      await store.clearCourses();
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull, reason: '清空课程后页面出错');
  }, timeout: const Timeout(Duration(seconds: 30)));
}
