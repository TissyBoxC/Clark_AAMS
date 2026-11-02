import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../models/course.dart';
import '../resources/app_colors.dart';
import '../resources/app_metrics.dart';
import '../resources/app_strings.dart';
import '../services/schedule_scope.dart';
import '../services/schedule_utils.dart';
import '../widgets/app_icons.dart';
import '../widgets/course_tile.dart';
import '../widgets/soft_ui.dart';
import '../widgets/timetable_grid.dart';
import 'course_editor.dart';
import 'workspace.dart' show WorkspaceTabs;

/// 课表页。
///
/// 手机端一屏看完整周：七天横向平铺，不再横向滚动；
/// 周次收进标题栏的下拉菜单，导入与布局切换并排放在右上角。
/// 「添加课程」不在这一页，统一收进「我的 → 课程管理」。
class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  int? _week;
  bool _listView = false;

  @override
  Widget build(BuildContext context) {
    final store = ScheduleScope.of(context);
    final settings = store.settings;
    final currentWeek = ScheduleUtils.currentWeek(settings, DateTime.now());
    final week = (_week ?? currentWeek).clamp(1, settings.maxWeeks);
    final courses = store.courses;
    final lessonCount = ScheduleUtils.lessonCount(settings, courses);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ScheduleToolbar(
              week: week,
              currentWeek: currentWeek,
              maxWeeks: settings.maxWeeks,
              listView: _listView,
              onWeekChanged: (value) => setState(() => _week = value),
              onToggleLayout: () => setState(() => _listView = !_listView),
            ),
            Expanded(
              child: courses.isEmpty
                  ? _EmptySchedule(onImport: () => goToImportTab(context))
                  : _listView
                  ? _ListView(
                      courses: courses
                          .where((c) => c.matchesWeek(week))
                          .toList(),
                    )
                  : _WeekGrid(
                      settings: settings,
                      courses: courses,
                      week: week,
                      maxLessons: lessonCount,
                      onCourseTap: (course) =>
                          showCourseEditor(context, course: course),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 顶部一行：周次下拉 + 导入 + 布局切换。
///
/// 导入不常用，但放在这里用户想用时一眼能看到；
/// 它和布局切换同一行，边距一致，不各占一块。
class _ScheduleToolbar extends StatelessWidget {
  const _ScheduleToolbar({
    required this.week,
    required this.currentWeek,
    required this.maxWeeks,
    required this.listView,
    required this.onWeekChanged,
    required this.onToggleLayout,
  });

  final int week;
  final int currentWeek;
  final int maxWeeks;
  final bool listView;
  final ValueChanged<int> onWeekChanged;
  final VoidCallback onToggleLayout;

  @override
  Widget build(BuildContext context) {
    final padding = AppMetrics.pagePadding(MediaQuery.sizeOf(context).width);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        padding,
        AppMetrics.sp3,
        padding,
        AppMetrics.sp2,
      ),
      child: Row(
        children: [
          Expanded(
            child: _WeekDropdown(
              week: week,
              currentWeek: currentWeek,
              maxWeeks: maxWeeks,
              onChanged: onWeekChanged,
            ),
          ),
          const SizedBox(width: AppMetrics.sp2),
          _ToolbarButton(
            label: AppStrings.importTab,
            icon: AppIcons.import,
            onPressed: () => goToImportTab(context),
          ),
          const SizedBox(width: AppMetrics.sp2),
          _ToolbarButton(
            label: listView ? '看表格' : '看列表',
            icon: listView ? AppIcons.schedule : AppIcons.home,
            onPressed: onToggleLayout,
          ),
        ],
      ),
    );
  }
}

/// 周次下拉：把原来的左右翻页按钮换成一个下拉菜单。
class _WeekDropdown extends StatelessWidget {
  const _WeekDropdown({
    required this.week,
    required this.currentWeek,
    required this.maxWeeks,
    required this.onChanged,
  });

  final int week;
  final int currentWeek;
  final int maxWeeks;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: AppMetrics.sp3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppMetrics.rPill),
        border: Border.all(color: AppColors.line),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: week,
          isExpanded: true,
          isDense: true,
          borderRadius: BorderRadius.circular(AppMetrics.rMd),
          icon: const Icon(
            AppIcons.chevronDown,
            size: 18,
            color: AppColors.ink500,
          ),
          style: const TextStyle(
            fontSize: AppMetrics.small,
            fontWeight: FontWeight.w600,
            color: AppColors.ink900,
          ),
          items: [
            for (var value = 1; value <= maxWeeks; value++)
              DropdownMenuItem(
                value: value,
                child: Text(
                  value == currentWeek
                      ? '${AppStrings.weekNumber(value)}（本周）'
                      : AppStrings.weekNumber(value),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (value) {
            if (value != null) {
              onChanged(value);
            }
          },
        ),
      ),
    );
  }
}

/// 右上角的小按钮：图标 + 文字，和下拉同高。
class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: AppMetrics.sp3),
          minimumSize: const Size(0, 40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          side: const BorderSide(color: AppColors.line),
          foregroundColor: AppColors.ink700,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: AppMetrics.small,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 整周课表：铺满可用空间，一屏看完全部七天。
class _WeekGrid extends StatelessWidget {
  const _WeekGrid({
    required this.settings,
    required this.courses,
    required this.week,
    required this.maxLessons,
    required this.onCourseTap,
  });

  final AppSettingsModel settings;
  final List<Course> courses;
  final int week;
  final int maxLessons;
  final ValueChanged<Course> onCourseTap;

  @override
  Widget build(BuildContext context) {
    final padding = AppMetrics.pagePadding(MediaQuery.sizeOf(context).width);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        padding,
        0,
        padding,
        AppMetrics.sp3,
      ),
      child: SoftCard(
        padding: const EdgeInsets.fromLTRB(
          AppMetrics.sp2,
          AppMetrics.sp3,
          AppMetrics.sp2,
          AppMetrics.sp3,
        ),
        child: TimetableGrid(
          settings: settings,
          courses: courses,
          week: week,
          maxLessons: maxLessons,
          fitToHeight: true,
          onCourseTap: onCourseTap,
        ),
      ),
    );
  }
}

class _EmptySchedule extends StatelessWidget {
  const _EmptySchedule({required this.onImport});

  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final padding = AppMetrics.pagePadding(MediaQuery.sizeOf(context).width);
    return ListView(
      padding: EdgeInsets.fromLTRB(
        padding,
        AppMetrics.sp3,
        padding,
        AppMetrics.sp6,
      ),
      children: [
        EmptyPanel(
          title: AppStrings.emptyScheduleTitle,
          body: AppStrings.emptyScheduleCopy,
          action: PrimaryButton(
            label: AppStrings.emptyScheduleImport,
            onPressed: onImport,
          ),
        ),
      ],
    );
  }
}

/// 列表视图：按天分组，课多的时候比格子好读。
class _ListView extends StatelessWidget {
  const _ListView({required this.courses});

  final List<Course> courses;

  @override
  Widget build(BuildContext context) {
    final padding = AppMetrics.pagePadding(MediaQuery.sizeOf(context).width);
    final sorted = [...courses]
      ..sort((a, b) {
        final byDay = a.dayOfWeek.compareTo(b.dayOfWeek);
        return byDay != 0
            ? byDay
            : a.startLesson.compareTo(b.startLesson);
      });

    return ListView(
      padding: EdgeInsets.fromLTRB(
        padding,
        AppMetrics.sp2,
        padding,
        AppMetrics.sp6,
      ),
      children: [
        if (sorted.isEmpty)
          const EmptyPanel(
            title: '这一周没有课',
            body: '换个周次看看，或者去「导入」把课表导进来。',
          )
        else
          for (final course in sorted)
            Padding(
              padding: const EdgeInsets.only(bottom: AppMetrics.sp2),
              child: CourseTile(
                course: course,
                onTap: () => showCourseEditor(context, course: course),
              ),
            ),
      ],
    );
  }
}

/// 切到导入页签。
void goToImportTab(BuildContext context) => WorkspaceTabs.go(context, 2);
