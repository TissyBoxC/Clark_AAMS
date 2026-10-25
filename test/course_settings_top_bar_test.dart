import 'package:clark_aams/resources/app_strings.dart';
import 'package:clark_aams/screens/course_settings/course_settings_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 课程设置页顶栏（P4-1）。
///
/// 它原本是 `_CourseSettingsPageState.build()` 里的内联一段（约 50 行），
/// 和列表、批量删除、悬浮按钮全挤在同一个方法里。
///
/// 抽成组件的理由：这是纯 UI，只靠回调与页面通信。
/// 内联时想测「批量删除模式下菜单是否隐藏」需要起整个页面并准备课表数据；
/// 抽出来后直接传 `batchDeleteMode` 就能测。
void main() {
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('普通模式下显示标题与更多菜单', (tester) async {
    await tester.pumpWidget(
      host(
        CourseSettingsTopBar(
          batchDeleteMode: false,
          onBack: () {},
          onImport: () {},
          onBatchAdd: () {},
          onBatchDelete: () {},
        ),
      ),
    );

    expect(find.text(AppStrings.courseSettingsTitle), findsOneWidget);
    expect(find.byIcon(Icons.more_horiz), findsOneWidget);
  });

  testWidgets('批量删除模式下隐藏更多菜单', (tester) async {
    // 批量删除时菜单必须消失：此时再打开「导入」会让用户以为还能导入，
    // 而实际上页面正处于「选中若干项准备删除」的状态
    await tester.pumpWidget(
      host(
        CourseSettingsTopBar(
          batchDeleteMode: true,
          onBack: () {},
          onImport: () {},
          onBatchAdd: () {},
          onBatchDelete: () {},
        ),
      ),
    );

    expect(find.byIcon(Icons.more_horiz), findsNothing);
  });

  testWidgets('返回按钮触发回调', (tester) async {
    var backPressed = false;
    await tester.pumpWidget(
      host(
        CourseSettingsTopBar(
          batchDeleteMode: false,
          onBack: () => backPressed = true,
          onImport: () {},
          onBatchAdd: () {},
          onBatchDelete: () {},
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump();
    expect(backPressed, isTrue);
  });

  testWidgets('菜单三项分别触发对应回调', (tester) async {
    var imported = false;
    var batchAdded = false;
    var batchDeleted = false;
    await tester.pumpWidget(
      host(
        CourseSettingsTopBar(
          batchDeleteMode: false,
          onBack: () {},
          onImport: () => imported = true,
          onBatchAdd: () => batchAdded = true,
          onBatchDelete: () => batchDeleted = true,
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.importCourses));
    await tester.pumpAndSettle();
    expect(imported, isTrue);

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.batchAdd));
    await tester.pumpAndSettle();
    expect(batchAdded, isTrue);

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.batchDelete));
    await tester.pumpAndSettle();
    expect(batchDeleted, isTrue);
  });
}
