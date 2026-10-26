import 'package:flutter/material.dart';

import '../../models/app_settings.dart';
import '../../models/course.dart';
import '../../resources/app_strings.dart';
import '../../services/schedule_scope.dart';
import '../../services/schedule_utils.dart';
import '../../widgets/top_bar.dart';
import 'home_style.dart';
import 'home_tab.dart' show SoftPanel;

/// 首页「课表」Tab：周切换 + 七列课表。
class ScheduleTab extends StatelessWidget {
  const ScheduleTab({
    required this.selectedWeek,
    required this.onWeekChanged,
    super.key,
  });

  final int? selectedWeek;
  final ValueChanged<int> onWeekChanged;

  @override
  Widget build(BuildContext context) {
    final store = ScheduleScope.of(context);
    final settings = store.settings;
    final week =
        (selectedWeek ?? ScheduleUtils.currentWeek(settings, DateTime.now()))
            .clamp(1, settings.maxWeeks);
    final monday = ScheduleUtils.weekMonday(settings, week);

    return Column(
      children: [
        const TopBar(title: AppStrings.scheduleTab),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 2, 18, 12),
          child: ScheduleHeaderCard(
            week: week,
            maxWeeks: settings.maxWeeks,
            onWeekChanged: onWeekChanged,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
            child: SoftPanel(
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
              child: Column(
                children: [
                  WeekHeader(monday: monday),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      child: ScheduleTable(
                        courses: store.courses,
                        selectedWeek: week,
                        maxLessons: ScheduleUtils.lessonCount(
                          settings,
                          store.courses,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ScheduleHeaderCard extends StatelessWidget {
  const ScheduleHeaderCard({
    required this.week,
    required this.maxWeeks,
    required this.onWeekChanged,
    super.key,
  });

  final int week;
  final int maxWeeks;
  final ValueChanged<int> onWeekChanged;

  @override
  Widget build(BuildContext context) {
    return SoftPanel(
      padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
      child: Row(
        children: [
          Image.asset(
            'assets/nav/nav_schedule_active.png',
            width: 88,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              AppStrings.thisWeekCourses,
              style: TextStyle(
                color: homeInk,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Container(
            width: 126,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xfffff2f5),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: homeLine),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: week,
                isExpanded: true,
                menuMaxHeight: 210,
                borderRadius: BorderRadius.circular(18),
                icon: const Icon(Icons.expand_more, color: homeLavender),
                dropdownColor: Colors.white,
                style: const TextStyle(
                  color: homeInk,
                  fontWeight: FontWeight.w800,
                ),
                items: [
                  for (var value = 1; value <= maxWeeks; value++)
                    DropdownMenuItem(
                      value: value,
                      child: Text(weekLabel(value)),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    onWeekChanged(value);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WeekHeader extends StatelessWidget {
  const WeekHeader({required this.monday, super.key});

  final DateTime monday;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    return Row(
      children: [
        SizedBox(
          width: 38,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Text(
              AppStrings.monthText(monday.month),
              style: const TextStyle(
                color: homeMuted,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        for (var index = 0; index < 7; index++)
          Expanded(
            child: DayHeader(
              label: ScheduleUtils.dayLabels[index],
              date: monday.add(Duration(days: index)),
              isToday: _sameDay(today, monday.add(Duration(days: index))),
            ),
          ),
      ],
    );
  }

  static bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class DayHeader extends StatelessWidget {
  const DayHeader({
    required this.label,
    required this.date,
    required this.isToday,
    super.key,
  });

  final String label;
  final DateTime date;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isToday ? const Color(0xfff0ecff) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: isToday ? Border.all(color: homeLine) : null,
      ),
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: isToday ? homeLavender : homeMuted,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            '${date.day}',
            style: TextStyle(
              color: isToday ? homeLavender : homeInk,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class ScheduleTable extends StatelessWidget {
  const ScheduleTable({
    required this.courses,
    required this.selectedWeek,
    required this.maxLessons,
    super.key,
  });

  static const _slotHeight = 64.0;

  final List<Course> courses;
  final int selectedWeek;
  final int maxLessons;

  @override
  Widget build(BuildContext context) {
    final visibleCourses = courses
        .where((course) => course.matchesWeek(selectedWeek))
        .toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 38,
          child: Column(
            children: [
              for (var lesson = 1; lesson <= maxLessons; lesson++)
                SizedBox(
                  height: _slotHeight,
                  child: Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.symmetric(
                      vertical: 2,
                      horizontal: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xfffff2f5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: homeLine),
                    ),
                    child: Text(
                      '$lesson',
                      style: const TextStyle(
                        color: homeLavender,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        for (var day = 1; day <= 7; day++)
          Expanded(
            child: DayColumn(
              courses: visibleCourses
                  .where((course) => course.dayOfWeek == day)
                  .toList(),
              maxLessons: maxLessons,
            ),
          ),
      ],
    );
  }
}

class DayColumn extends StatelessWidget {
  const DayColumn({required this.courses, required this.maxLessons, super.key});

  static const _slotHeight = 64.0;

  final List<Course> courses;
  final int maxLessons;

  @override
  Widget build(BuildContext context) {
    final sorted = [...courses]
      ..sort((a, b) => a.startLesson.compareTo(b.startLesson));
    return SizedBox(
      height: _slotHeight * maxLessons,
      child: Stack(
        children: [
          for (final course in sorted)
            if (course.startLesson <= maxLessons && course.endLesson >= 1)
              Positioned(
                left: 0,
                right: 0,
                top: _topFor(course),
                height: _heightFor(course),
                child: CourseBlock(course: course),
              ),
        ],
      ),
    );
  }

  double _topFor(Course course) {
    return (course.startLesson.clamp(1, maxLessons).toInt() - 1) * _slotHeight;
  }

  double _heightFor(Course course) {
    final start = course.startLesson.clamp(1, maxLessons).toInt();
    final end = course.endLesson.clamp(1, maxLessons).toInt();
    return (end - start + 1) * _slotHeight;
  }
}

class CourseBlock extends StatelessWidget {
  const CourseBlock({required this.course, super.key});

  final Course course;

  @override
  Widget build(BuildContext context) {
    final store = ScheduleScope.of(context);
    final color = ScheduleUtils.colorForCourse(course);
    final foreground = color.computeLuminance() > 0.65
        ? Colors.black87
        : Colors.white;
    final location = course.location.trim();
    final showLocation = course.duration > 1 && location.isNotEmpty;

    return Container(
      margin: const EdgeInsets.fromLTRB(2, 3, 2, 3),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        shadowColor: color.withAlpha(70),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => showLessonInfo(context, store.settings, course),
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.name,
                  maxLines: showLocation ? 2 : course.duration * 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    height: 1.18,
                  ),
                ),
                if (showLocation) ...[
                  const SizedBox(height: 3),
                  Text(
                    location,
                    maxLines: course.duration * 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground.withAlpha(220),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 点击课程块弹出的详情。
void showLessonInfo(
  BuildContext context,
  AppSettingsModel settings,
  Course course,
) {
  showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(course.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(course.weekText),
            const SizedBox(height: 6),
            Text(
              '${ScheduleUtils.dayLabels[course.dayOfWeek - 1]}  ${lessonRangeLabel(course.startLesson, course.endLesson)}',
            ),
            const SizedBox(height: 6),
            Text(ScheduleUtils.timeRange(settings, course)),
            const SizedBox(height: 6),
            if (course.teacher.isNotEmpty) ...[
              Text(course.teacher),
              const SizedBox(height: 6),
            ],
            if (course.rawTime.isNotEmpty) ...[
              Text(course.rawTime),
              const SizedBox(height: 6),
            ],
            Text(
              course.location.isEmpty
                  ? AppStrings.locationNotSet
                  : course.location,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.confirm),
          ),
        ],
      );
    },
  );
}
