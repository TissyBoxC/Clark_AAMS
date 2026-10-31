import 'package:clark_aams/models/app_settings.dart';
import 'package:clark_aams/resources/app_theme.dart';
import 'package:clark_aams/screens/course_settings_page.dart';
import 'package:clark_aams/screens/term_setup_page.dart';
import 'package:clark_aams/services/class_schedule_store.dart';
import 'package:clark_aams/services/schedule_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _phone = Size(390, 844);

Future<ClassScheduleStore> _store() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  return ClassScheduleStore.load();
}

Widget _host(ClassScheduleStore store, Widget child) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: ScheduleScope(store: store, child: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('课程设置页能正常显示', (tester) async {
    tester.view.physicalSize = _phone;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final store = await _store();
    await tester.pumpWidget(_host(store, const CourseSettingsPage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull, reason: '课程设置页渲染时抛了异常');
  });

  testWidgets('学期与作息设置页能正常显示', (tester) async {
    tester.view.physicalSize = _phone;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final store = await _store();
    final settings = AppSettingsModel.defaults;
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

    expect(settings.maxWeeks, greaterThan(0));
    expect(tester.takeException(), isNull, reason: '学期设置页渲染时抛了异常');
  });
}
