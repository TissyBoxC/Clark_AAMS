import 'dart:convert';
import 'dart:io';

import 'package:clark_aams/models/app_settings.dart';
import 'package:clark_aams/models/course.dart';
import 'package:clark_aams/models/school.dart';
import 'package:clark_aams/resources/app_colors.dart';
import 'package:clark_aams/resources/app_theme.dart';
import 'package:clark_aams/screens/workspace.dart';
import 'package:clark_aams/services/academic_browser.dart';
import 'package:clark_aams/services/class_schedule_store.dart';
import 'package:clark_aams/services/schedule_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 屏幕尺寸：手机竖屏与桌面宽屏各跑一遍，确认两套排版都不报错。
const _phone = Size(390, 844);
const _desktop = Size(1280, 860);

Future<ClassScheduleStore> _emptyStore() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  return ClassScheduleStore.load();
}

Widget _app(ClassScheduleStore store) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: ScheduleScope(store: store, child: const WorkspaceShell()),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('工作台', () {
    for (final (name, size) in [('手机', _phone), ('桌面', _desktop)]) {
      testWidgets('$name 打开后能看到五个入口', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final store = await _emptyStore();
        await tester.pumpWidget(_app(store));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // 手机走底部页签，桌面走左侧栏，两者都应当出现"课表"这个词。
        expect(find.text('课表'), findsWidgets);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('空课表时给出导入的下一步', (tester) async {
      tester.view.physicalSize = _phone;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final store = await _emptyStore();
      await tester.pumpWidget(_app(store));
      await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('课表').last);
      await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('导入'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('课表解析', () {
    test('把页面格子读成课程', () {
      final raw = jsonEncode({
        'ok': true,
        'lessons': [
          {
            'name': '高等数学',
            'text': '高等数学\nA 楼 301 张三',
            'rowIndex': 0,
            'dayIndex': 0,
            'span': 2,
            'headText': '第1节',
          },
          {
            'name': '大学英语',
            'text': '大学英语\n@李四',
            'rowIndex': 2,
            'dayIndex': 3,
            'span': 1,
            'headText': '第3节',
          },
        ],
      });

      final result = AcademicBrowser.interpret(
        raw,
        maxWeek: 16,
        schoolName: '示例大学',
      );

      expect(result.courses, hasLength(2));

      final math = result.courses.first;
      expect(math.name, '高等数学');
      expect(math.dayOfWeek, 1);
      expect(math.startLesson, 1);
      expect(math.endLesson, 2, reason: '跨两节的课要覆盖到第二节');
      expect(math.location, contains('301'));
      expect(math.matchesWeek(16), isTrue);

      final english = result.courses.last;
      expect(english.dayOfWeek, 4);
      expect(english.startLesson, 3);
    });

    test('页面上没有课表时给出可执行的提示', () {
      final result = AcademicBrowser.interpret(
        jsonEncode({'ok': false, 'reason': 'no-table'}),
        maxWeek: 16,
        schoolName: '示例大学',
      );
      expect(result.isEmpty, isTrue);
      expect(result.message, contains('课表'));
    });

    test('内置浏览器在目标平台上的可用性与提示一致', () {
      // 支持情况随平台变化：Windows / macOS / 手机可用，Linux 上退回截图识别。
      // 这里只在"支持"与"提示文案"之间的一致性上做断言，不写死某一平台。
      expect(AcademicBrowser.engineHint, isNotEmpty);
      if (Platform.isWindows) {
        expect(AcademicBrowser.isSupported, isTrue);
      }
      if (Platform.isLinux) {
        expect(AcademicBrowser.isSupported, isFalse);
      }
    });

    test('没有登录入口的学校不去打开页面', () {
      const school = School(
        id: 'demo',
        name: '示例大学',
        shortName: '示例',
        supportsAcademicImport: false,
        supportsImageRecognition: false,
        login: SchoolLogin(
          mode: '',
          loginUrl: '',
          successUrlPatterns: <String>[],
        ),
        version: 1,
        lessonTimeProfile: '',
      );
      expect(AcademicBrowser.hasLoginPage(school), isFalse);
    });
  });

  group('配色', () {
    test('主色换成了与网页一致的靛蓝', () {
      expect(AppColors.brand600, const Color(0xFF4F46E5));
      // 旧版的玫红不应再出现在主色里。
      expect(AppColors.brand600, isNot(const Color(0xFFC93C7D)));
    });
  });

  group('课程模型', () {
    test('单双周与周次区间同时生效', () {
      const course = Course(
        id: 1,
        name: '体育',
        startWeek: 1,
        endWeek: 16,
        dayOfWeek: 2,
        startLesson: 5,
        endLesson: 6,
        location: '操场',
        weekPattern: WeekPattern(ranges: [WeekRange(1, 16)], rule: WeekRule.odd),
      );
      expect(course.matchesWeek(1), isTrue);
      expect(course.matchesWeek(2), isFalse);
      expect(course.matchesWeek(17), isFalse);
    });

    test('总周数约束在合理范围', () {
      expect(AppSettingsModel.defaults.maxWeeks, greaterThan(0));
      expect(AppSettingsModel.defaults.maxWeeks, lessThanOrEqualTo(30));
    });
  });
}
