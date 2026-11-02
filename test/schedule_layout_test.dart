import 'package:clark_aams/models/course.dart';
import 'package:clark_aams/resources/app_theme.dart';
import 'package:clark_aams/screens/schedule_page.dart';
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
    // 每天都排课，验证七列都存在且都在屏内。
    for (var day = 1; day <= 7; day++) {
      await store.addCourse(
        Course(
          id: day,
          name: '第$day天课程',
          startWeek: 1,
          endWeek: 16,
          dayOfWeek: day,
          startLesson: 1,
          endLesson: 2,
          location: 'A$day',
          teacher: '',
          weekPattern: const WeekPattern(ranges: [WeekRange(1, 16)]),
        ),
      );
    }
  });
  return store;
}

Widget _host(ClassScheduleStore store) {
  return ScheduleScope(
    store: store,
    child: MaterialApp(
      theme: AppTheme.light(),
      home: const SchedulePage(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('手机上一屏显示完整一周七天', (tester) async {
    tester.view.physicalSize = _phone;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final store = await _store(tester);
    await tester.pumpWidget(_host(store));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull, reason: '课表页渲染出错');

    // 七天标题都在。
    for (final label in ['一', '二', '三', '四', '五', '六', '日']) {
      expect(find.text(label), findsWidgets, reason: '缺少星期 $label');
    }

    // 横向不能出现滚动：出现就说明一屏放不下，用户得滑。
    final scrollables = tester
        .widgetList<Scrollable>(find.byType(Scrollable))
        .where((s) => s.axisDirection == AxisDirection.right ||
            s.axisDirection == AxisDirection.left);
    expect(scrollables, isEmpty, reason: '课表仍在横向滚动，无法一屏看完一周');

    // 最后一列（周日）必须落在屏幕宽度内。
    final sunday = tester.getRect(find.text('日').last);
    expect(sunday.right, lessThanOrEqualTo(_phone.width),
        reason: '周日列超出屏幕');
  }, timeout: const Timeout(Duration(seconds: 40)));

  testWidgets('周次选择是下拉菜单而不是左右按钮', (tester) async {
    tester.view.physicalSize = _phone;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final store = await _store(tester);
    await tester.pumpWidget(_host(store));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(DropdownButton<int>), findsOneWidget,
        reason: '没有找到周次下拉菜单');
    expect(find.textContaining('第 1 周'), findsWidgets);
  }, timeout: const Timeout(Duration(seconds: 40)));

  testWidgets('导入与布局切换在右上角同一行', (tester) async {
    tester.view.physicalSize = _phone;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final store = await _store(tester);
    await tester.pumpWidget(_host(store));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final importRect = tester.getRect(find.text('导入').first);
    final toggleRect = tester.getRect(find.text('看列表').first);

    // 同一行：垂直中心接近。
    expect((importRect.center.dy - toggleRect.center.dy).abs(), lessThan(8),
        reason: '导入与布局切换不在同一行');
    // 都在右侧：右边缘应当贴在屏幕右边附近。
    expect(toggleRect.right, greaterThan(_phone.width * 0.6));
  }, timeout: const Timeout(Duration(seconds: 40)));

  testWidgets('课表页不再有添加课程按钮', (tester) async {
    tester.view.physicalSize = _phone;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final store = await _store(tester);
    await tester.pumpWidget(_host(store));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('添加课程'), findsNothing,
        reason: '添加课程应并入课程设置，不再出现在课表页');
  }, timeout: const Timeout(Duration(seconds: 40)));
}
