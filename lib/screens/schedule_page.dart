import 'package:flutter/material.dart';

import '../models/course.dart';
import '../resources/app_colors.dart';
import '../resources/app_metrics.dart';
import '../resources/app_strings.dart';
import '../services/schedule_scope.dart';
import '../services/schedule_utils.dart';
import '../widgets/app_icons.dart';
import '../widgets/soft_ui.dart';
import '../widgets/timetable_grid.dart';
import 'course_editor.dart';
import 'workspace.dart' show goToImportTab;

/// 课表页：周次切换 + 七列课表 + 列表视图。
///
/// 手机默认看课表网格（横向可滚动），桌面端窗口够宽时直接铺满。
/// 也提供「列表」视图：课多的时候按天看比格子更好读。
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

    return PageScaffold(
      title: AppStrings.scheduleTab,
      description: '按周查看课程。点课程可以改节次、教室或周次。',
      actions: [
        QuietButton(
          label: _listView ? '看表格' : '看列表',
          icon: _listView ? AppIcons.schedule : AppIcons.home,
          onPressed: () => setState(() => _listView = !_listView),
        ),
        PrimaryButton(
          label: AppStrings.addCourse,
          icon: AppIcons.plus,
          onPressed: () => showCourseEditor(context, defaultWeek: week),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SoftCard(
            padding: const EdgeInsets.all(AppMetrics.sp3),
            child: _WeekPicker(
              week: week,
              currentWeek: currentWeek,
              maxWeeks: settings.maxWeeks,
              onChanged: (value) => setState(() => _week = value),
            ),
          ),
          const SizedBox(height: AppMetrics.sp4),
          if (courses.isEmpty)
            SoftCard(
              child: EmptyPanel(
                title: AppStrings.emptyScheduleTitle,
                body: AppStrings.emptyScheduleCopy,
                action: PrimaryButton(
                  label: AppStrings.emptyScheduleImport,
                  onPressed: () => goToImportTab(context),
                ),
              ),
            )
          else if (_listView)
            _ListView(
              courses: courses.where((c) => c.matchesWeek(week)).toList(),
            )
          else
            SoftCard(
              padding: const EdgeInsets.all(AppMetrics.sp3),
              child: TimetableGrid(
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
    );
  }
}

class _WeekPicker extends StatelessWidget {
  const _WeekPicker({
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
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: maxWeeks,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final value = index + 1;
          final selected = value == week;
          return GestureDetector(
            onTap: () => onChanged(value),
            child: AnimatedContainer(
              duration: AppMetrics.fast,
              curve: AppMetrics.ease,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected ? AppColors.brand600 : AppColors.surfaceSunken,
                borderRadius: BorderRadius.circular(AppMetrics.rPill),
              ),
              child: Row(
                children: [
                  Text(
                    AppStrings.weekNumber(value),
                    style: TextStyle(
                      fontSize: AppMetrics.small,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected ? AppColors.inkInverse : AppColors.ink600,
                    ),
                  ),
                  if (value == currentWeek) ...[
                    const SizedBox(width: 4),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.inkInverse
                            : AppColors.brand600,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ListView extends StatelessWidget {
  const _ListView({required this.courses});

  final List<Course> courses;

  @override
  Widget build(BuildContext context) {
    final settings = ScheduleScope.of(context).settings;

    if (courses.isEmpty) {
      return const SoftCard(
        child: EmptyPanel(
          title: AppStrings.noCoursesToday,
          body: '这一周没有排课。换一个周次看看，或者确认课程周次设置是否正确。',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var day = 1; day <= 7; day++)
          Builder(
            builder: (context) {
              final dayCourses =
                  courses.where((c) => c.dayOfWeek == day).toList()
                    ..sort((a, b) => a.startLesson.compareTo(b.startLesson));
              if (dayCourses.isEmpty) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: AppMetrics.sp4),
                child: SoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CardHeading(title: AppStrings.fullWeekdays[day - 1]),
                      const SizedBox(height: AppMetrics.sp3),
                      for (final course in dayCourses)
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppMetrics.sp2,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      course.name,
                                      style: const TextStyle(
                                        fontSize: AppMetrics.body,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.ink900,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      [
                                            AppStrings.lessonRangeText(
                                              course.startLesson,
                                              course.endLesson,
                                            ),
                                            ScheduleUtils.timeRange(
                                              settings,
                                              course,
                                            ),
                                            if (course.location
                                                .trim()
                                                .isNotEmpty)
                                              course.location.trim(),
                                            course.weekText,
                                          ]
                                          .where((value) => value.isNotEmpty)
                                          .join(' · '),
                                      style: const TextStyle(
                                        fontSize: AppMetrics.tiny,
                                        color: AppColors.ink500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: AppStrings.editCourse,
                                icon: const Icon(AppIcons.edit, size: 20),
                                onPressed: () =>
                                    showCourseEditor(context, course: course),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
