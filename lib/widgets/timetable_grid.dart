import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../models/course.dart';
import '../resources/app_colors.dart';
import '../resources/app_metrics.dart';
import '../resources/app_strings.dart';
import '../services/schedule_utils.dart';

/// 七列课表。手机上一屏看完一周七天，不再横向滚动。
///
/// 手机上宽度只有 360~430，固定 96 像素一天必然要横向滚，
/// 用户就看不到整周。这里改成按可用宽度均分七列，行高也按屏幕高度收缩，
/// 保证「一周所有课都在这屏里」。宽屏窗口够大时行高回到舒适值。
class TimetableGrid extends StatelessWidget {
  const TimetableGrid({
    required this.settings,
    required this.courses,
    required this.week,
    required this.maxLessons,
    this.fitToHeight = false,
    this.onCourseTap,
    super.key,
  });

  final AppSettingsModel settings;
  final List<Course> courses;
  final int week;
  final int maxLessons;

  /// 为 true 时把整张表压进父级给的可用高度（手机端用）。
  final bool fitToHeight;
  final ValueChanged<Course>? onCourseTap;

  /// 舒适行高：宽屏窗口里每节课的格子高度。
  static const double _rowHeight = 62;

  /// 手机上一节课格子的最小高度，再小就放不下课程名。
  static const double _minRowHeight = 34;

  static const double _minGutterWidth = 22;
  static const double _maxGutterWidth = 46;

  /// 七列各自最小宽度：手机上一列就是屏幕宽减节次列后平分。
  static const double _headerHeight = 52;

  @override
  Widget build(BuildContext context) {
    final visible = courses.where((course) => course.matchesWeek(week)).toList();
    final today = DateTime.now().weekday;

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        // 手机宽度窄，节次列跟着收窄，剩余宽度平分给七天。
        final gutterWidth = available >= 560
            ? _maxGutterWidth
            : _minGutterWidth;
        final dayWidth = (available - gutterWidth) / 7;

        var rowHeight = _rowHeight;
        if (fitToHeight && constraints.maxHeight.isFinite) {
          final usable = constraints.maxHeight - _headerHeight - AppMetrics.sp2;
          final fitted = usable / maxLessons;
          // 下限要跟着可用高度走：320 宽的窄屏上可用高度只有 470 左右，
          // 若强行保底 _minRowHeight（34），13 节课总高会超出容器并溢出。
          final minRow = _minRowHeight < fitted ? _minRowHeight : fitted;
          rowHeight = fitted.clamp(minRow, _rowHeight);
        }

        return Column(
          children: [
            SizedBox(
              height: _headerHeight,
              child: _DayHeaderRow(
                settings: settings,
                week: week,
                today: today,
                gutterWidth: gutterWidth,
                dayWidth: dayWidth,
              ),
            ),
            const SizedBox(height: AppMetrics.sp2),
            SizedBox(
              height: rowHeight * maxLessons,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LessonGutter(
                    maxLessons: maxLessons,
                    width: gutterWidth,
                    rowHeight: rowHeight,
                  ),
                  for (var day = 1; day <= 7; day++)
                    SizedBox(
                      width: dayWidth,
                      child: _DayColumn(
                        height: rowHeight * maxLessons,
                        rowHeight: rowHeight,
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
    required this.gutterWidth,
    required this.dayWidth,
  });

  final AppSettingsModel settings;
  final int week;
  final int today;
  final double gutterWidth;
  final double dayWidth;

  @override
  Widget build(BuildContext context) {
    final monday = ScheduleUtils.weekMonday(settings, week);

    return Row(
      children: [
        SizedBox(
          width: gutterWidth,
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
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.brand050 : Colors.transparent,
        borderRadius: BorderRadius.circular(AppMetrics.rSm),
        border: highlighted
            ? Border.all(color: AppColors.brand200)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              height: 1.1,
              fontWeight: FontWeight.w600,
              color: highlighted ? AppColors.brand700 : AppColors.ink500,
            ),
          ),
          Text(
            '${date.day}',
            maxLines: 1,
            style: TextStyle(
              fontSize: 12,
              height: 1.1,
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
  const _LessonGutter({
    required this.maxLessons,
    required this.width,
    required this.rowHeight,
  });

  final int maxLessons;
  final double width;
  final double rowHeight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      // 每格高度必须严格等于 rowHeight，不能再加垂直外边距，
      // 否则 maxLessons 个格子会比外层给的高度更高，整列溢出。
      child: Column(
        children: [
          for (var lesson = 1; lesson <= maxLessons; lesson++)
            Container(
              height: rowHeight,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surfaceSunken,
                borderRadius: BorderRadius.circular(AppMetrics.rSm),
              ),
              child: Text(
                '$lesson',
                style: TextStyle(
                  fontSize: width < 30 ? 10 : AppMetrics.tiny,
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
    required this.rowHeight,
    required this.courses,
    required this.maxLessons,
    required this.settings,
    required this.onCourseTap,
  });

  final double height;
  final double rowHeight;
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
              top: (lesson - 1) * rowHeight + 1,
              left: 2,
              right: 2,
              height: rowHeight - 2,
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
                top: (_start(course) - 1) * rowHeight + 1,
                left: 2,
                right: 2,
                height: _span(course) * rowHeight - 2,
                child: _CourseBlock(
                  course: course,
                  rowHeight: rowHeight,
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
    required this.rowHeight,
    required this.onTap,
  });

  final Course course;
  final double rowHeight;
  final ValueChanged<Course>? onTap;

  @override
  Widget build(BuildContext context) {
    final tone = AppColors.courseTone(
      course.name.codeUnits.fold<int>(0, (a, b) => a + b),
    );
    // 格子太矮时不塞第二行文字，否则文字会被裁掉一半。
    final roomy = course.duration > 1 && rowHeight * course.duration >= 56;
    final showLocation = roomy && course.location.trim().isNotEmpty;

    return Material(
      color: tone[0],
      borderRadius: BorderRadius.circular(AppMetrics.rSm),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap == null ? null : () => onTap!(course),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  course.name,
                  maxLines: showLocation ? 2 : course.duration * 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    color: tone[1],
                  ),
                ),
              ),
              if (showLocation) ...[
                const SizedBox(height: 1),
                Text(
                  course.location.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    height: 1.1,
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
