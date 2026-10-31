import 'package:clark_aams/models/course.dart';
import 'package:clark_aams/resources/app_theme.dart';
import 'package:clark_aams/screens/auth_page.dart';
import 'package:clark_aams/screens/course_settings_page.dart';
import 'package:clark_aams/screens/questions_page.dart';
import 'package:clark_aams/screens/schedule_page.dart';
import 'package:clark_aams/screens/settings_page.dart';
import 'package:clark_aams/screens/term_setup_page.dart';
import 'package:clark_aams/screens/workspace.dart';
import 'package:clark_aams/services/class_schedule_store.dart';
import 'package:clark_aams/services/schedule_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 常见机型宽度，从最窄的 iPhone SE 到平板。
const _sizes = <String, Size>{
  'iPhone SE': Size(320, 568),
  '常用手机': Size(390, 844),
  '大屏手机': Size(430, 932),
  '平板': Size(834, 1194),
};

Future<ClassScheduleStore> _store(WidgetTester tester) async {
  late ClassScheduleStore store;
  await tester.runAsync(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    store = await ClassScheduleStore.load();
    await store.addCourse(
      const Course(
        id: 1,
        name: '概率论与数理统计',
        startWeek: 1,
        endWeek: 16,
        dayOfWeek: 1,
        startLesson: 1,
        endLesson: 2,
        location: '第三教学楼 401',
        teacher: '王老师',
        weekPattern: WeekPattern(ranges: [WeekRange(1, 16)]),
      ),
    );
    await store.addCourse(
      const Course(
        id: 2,
        name: '马克思主义基本原理',
        startWeek: 1,
        endWeek: 16,
        dayOfWeek: 3,
        startLesson: 5,
        endLesson: 6,
        location: '第二教学楼 108',
        teacher: '李老师',
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

void _expectNoOverflow(WidgetTester tester, String page, String size) {
  final error = tester.takeException();
  if (error == null) {
    return;
  }
  fail('$page 在 $size 下出错：$error');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final pages = <String, Widget Function()>{
    '工作台': () => const WorkspaceShell(),
    '课表页': () => const SchedulePage(),
    '课程设置': () => const CourseSettingsPage(),
    '我的': () => const SettingsPage(),
    '学期与作息': () => TermSetupPage(
      initialStartTimes: const [],
      initialTermStartDate: DateTime(2026, 9, 1),
      lessonCount: 12,
      profiles: const [],
      notice: '',
    ),
    '账号': () => const AuthPage(),
    '问答': () => const QuestionsPage(),
  };

  for (final entry in pages.entries) {
    for (final size in _sizes.entries) {
      testWidgets('${entry.key} 在 ${size.key} 下不溢出', (tester) async {
        tester.view.physicalSize = size.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final store = await _store(tester);
        await tester.pumpWidget(_host(store, entry.value()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        _expectNoOverflow(tester, entry.key, size.key);
      }, timeout: const Timeout(Duration(seconds: 40)));
    }
  }
}
