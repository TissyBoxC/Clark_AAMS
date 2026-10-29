import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../models/course.dart';
import '../resources/app_colors.dart';
import '../resources/app_metrics.dart';
import '../resources/app_strings.dart';
import '../services/schedule_utils.dart';

/// 七列课表。
///
/// 手机上横向滚动（每列最少 96 像素，挤不下就滚动，绝不压缩到看不清）；
/// 桌面端窗口变宽后自动铺满，不再滚动。
class TimetableGrid extends StatelessWidget {
  const TimetableGrid({
    required this.settings,
    required this.courses,
    required this.week,
    required this.maxLessons,
    this.onCourseTap,
    super.key,
  });

  final AppSettingsModel settings;
  final List<Course> courses;
  final int week;
  final int maxLessons;
  final ValueChanged<Course>? onCourseTap;

  static const double _rowHeight = 62;
  static const double _minDayWidth = 96;
  static const double _gutterWidth = 46;

  @override
  Widget build(BuildContext context) {
    final visible = courses
        .where((course) => course.matchesWeek(week))
        .toList();
    final today = DateTime.now().weekday;
    final tableWidth = _gutterWidth + _minDayWidth * 7;

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        final width = available > tableWidth ? available : tableWidth;

        final table = SizedBox(
          width: width,
          child: Column(
            children: [
              _DayHeaderRow(
                settings: settings,
                week: week,
                today: today,
                dayWidth: (width - _gutterWidth) / 7,
              ),
              const SizedBox(height: AppMetrics.sp2),
              SizedBox(
                height: _rowHeight * maxLessons,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LessonGutter(maxLessons: maxLessons),
                    for (var day = 1; day <= 7; day++)
                      SizedBox(
                        width: (width - _gutterWidth) / 7,
                        child: _DayColumn(
                          height: _rowHeight * maxLessons,
                          courses: visible
                              .where((c) => c.dayOfWeek == day)
                              .toList(),
                          maxLessons: maxLessons,
                          settings: settings,
                          onCourseTap: onCourseTap,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );

        if (available >= tableWidth) {
          return table;
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: table,
        );
      },
    );
  }
}

class _DayHeaderRow extends StatelessWidget {
  const _DayHeaderRow({
    required this.settings,
    required this.week,
    required this.today,
    required this.dayWidth,
  });

  final AppSettingsModel settings;
  final int week;
  final int today;
  final double dayWidth;

  @override
  Widget build(BuildContext context) {
    final monday = ScheduleUtils.weekMonday(settings, week);

    return Row(
      children: [
        SizedBox(
          width: TimetableGrid._gutterWidth,
          child: Text(
            AppStrings.monthText(monday.month),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: AppMetrics.tiny,
              fontWeight: FontWeight.w600,
              color: AppColors.ink500,
            ),
          ),
        ),
        for (var index = 0; index < 7; index++)
          SizedBox(
            width: dayWidth,
            child: _DayHeader(
              label: AppStrings.weekLabels[index],
              date: monday.add(Duration(days: index)),
              highlighted: today == index + 1,
            ),
          ),
      ],
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({
    required this.label,
    required this.date,
    required this.highlighted,
  });

  final String label;
  final DateTime date;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.brand050 : Colors.transparent,
        borderRadius: BorderRadius.circular(AppMetrics.rMd),
        border: highlighted ? Border.all(color: AppColors.brand200) : null,
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: AppMetrics.tiny,
              fontWeight: FontWeight.w600,
              color: highlighted ? AppColors.brand700 : AppColors.ink500,
            ),
          ),
          Text(
            '${date.day}',
            style: TextStyle(
              fontSize: AppMetrics.small,
              fontWeight: FontWeight.w600,
              color: highlighted ? AppColors.brand700 : AppColors.ink900,
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonGutter extends StatelessWidget {
  const _LessonGutter({required this.maxLessons});

  final int maxLessons;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: TimetableGrid._gutterWidth,
      child: Column(
        children: [
          for (var lesson = 1; lesson <= maxLessons; lesson++)
            Container(
              height: TimetableGrid._rowHeight,
              alignment: Alignment.center,
              margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceSunken,
                borderRadius: BorderRadius.circular(AppMetrics.rSm),
              ),
              child: Text(
                '$lesson',
                style: const TextStyle(
                  fontSize: AppMetrics.tiny,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.height,
    required this.courses,
    required this.maxLessons,
    required this.settings,
    required this.onCourseTap,
  });

  final double height;
  final List<Course> courses;
  final int maxLessons;
  final AppSettingsModel settings;
  final ValueChanged<Course>? onCourseTap;

  @override
  Widget build(BuildContext context) {
    final sorted = [...courses]
      ..sort((a, b) => a.startLesson.compareTo(b.startLesson));

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          // 底格：给每一节留一个浅色位置，空着也看得出"这一节没有课"
          for (var lesson = 1; lesson <= maxLessons; lesson++)
            Positioned(
              top: (lesson - 1) * TimetableGrid._rowHeight + 2,
              left: 3,
              right: 3,
              height: TimetableGrid._rowHeight - 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surfaceSunken.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(AppMetrics.rSm),
                ),
              ),
            ),
          for (final course in sorted)
            if (course.startLesson <= maxLessons && course.endLesson >= 1)
              Positioned(
                top: (_start(course) - 1) * TimetableGrid._rowHeight + 2,
                left: 3,
                right: 3,
                height: _span(course) * TimetableGrid._rowHeight - 4,
                child: _CourseBlock(
                  course: course,
                  settings: settings,
                  onTap: onCourseTap,
                ),
              ),
        ],
      ),
    );
  }

  int _start(Course course) => course.startLesson.clamp(1, maxLessons);

  int _span(Course course) {
    final start = _start(course);
    final end = course.endLesson.clamp(1, maxLessons);
    return (end - start + 1).clamp(1, maxLessons);
  }
}

class _CourseBlock extends StatelessWidget {
  const _CourseBlock({
    required this.course,
    required this.settings,
    required this.onTap,
  });

  final Course course;
  final AppSettingsModel settings;
  final ValueChanged<Course>? onTap;

  @override
  Widget build(BuildContext context) {
    final tone = AppColors.courseTone(
      course.name.codeUnits.fold<int>(0, (a, b) => a + b),
    );
    final showLocation =
        course.duration > 1 && course.location.trim().isNotEmpty;

    return Material(
      color: tone[0],
      borderRadius: BorderRadius.circular(AppMetrics.rSm),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap == null ? null : () => onTap!(course),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                course.name,
                maxLines: showLocation ? 2 : course.duration * 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                  color: tone[1],
                ),
              ),
              if (showLocation) ...[
                const SizedBox(height: 2),
                Text(
                  course.location.trim(),
                  maxLines: course.duration * 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.2,
                    color: tone[1].withValues(alpha: 0.78),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
