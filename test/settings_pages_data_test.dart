import 'package:clark_aams/models/course.dart';
import 'package:clark_aams/resources/app_theme.dart';
import 'package:clark_aams/screens/course_settings_page.dart';
import 'package:clark_aams/screens/schedule_page.dart';
import 'package:clark_aams/services/class_schedule_store.dart';
import 'package:clark_aams/services/schedule_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _phone = Size(390, 844);

/// 装机真实数据。store 的保存链路会去同步桌面小组件，
/// 那一步要走平台通道，必须放在 runAsync 里，否则测试会一直等。
Future<ClassScheduleStore> _storeWithCourses(WidgetTester tester) async {
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

Widget _host(ClassScheduleStore store, Widget child) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: ScheduleScope(store: store, child: child),
  );
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('有课程时课程设置页能显示课程', (tester) async {
    tester.view.physicalSize = _phone;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final store = await _storeWithCourses(tester);
    await tester.pumpWidget(_host(store, const CourseSettingsPage()));
    await _settle(tester);

    expect(tester.takeException(), isNull, reason: '有课程时渲染抛异常');
    expect(find.text('高等数学'), findsWidgets);
  }, timeout: const Timeout(Duration(seconds: 30)));

  testWidgets('课表页在有课程时能正常显示', (tester) async {
    tester.view.physicalSize = _phone;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final store = await _storeWithCourses(tester);
    await tester.pumpWidget(_host(store, const SchedulePage()));
    await _settle(tester);

    expect(tester.takeException(), isNull, reason: '课表页渲染抛异常');
  }, timeout: const Timeout(Duration(seconds: 30)));
}
