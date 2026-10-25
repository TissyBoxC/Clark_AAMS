import 'package:flutter/material.dart';

import '../../models/app_settings.dart';
import '../../models/course.dart';
import '../../resources/app_strings.dart';
import '../../services/schedule_scope.dart';
import '../../services/schedule_utils.dart';
import '../../widgets/top_bar.dart';
import 'home_style.dart';

/// 首页「首页」Tab：问候卡、指标卡、今日课程。
class HomeTab extends StatelessWidget {
  const HomeTab({required this.onOpenSchedule, super.key});

  final VoidCallback onOpenSchedule;

  @override
  Widget build(BuildContext context) {
    final store = ScheduleScope.of(context);
    final settings = store.settings;
    final today = DateTime.now();
    final week = ScheduleUtils.currentWeek(settings, today);
    final allTodayCourses =
        store.courses
            .where(
              (course) =>
                  course.matchesWeek(week) && course.dayOfWeek == today.weekday,
            )
            .toList()
          ..sort((a, b) => a.startLesson.compareTo(b.startLesson));
    final todayCourses = allTodayCourses
        .where((course) => isCourseNotFinished(settings, course, today))
        .toList();
    final todayStatusText = allTodayCourses.isEmpty
        ? AppStrings.noCoursesToday
        : AppStrings.coursesFinishedToday;

    return Column(
      children: [
        TopBar(
          title: AppStrings.appName,
          titleIcon: Image.asset('assets/logo/logo.png', width: 28, height: 28),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
            children: [
              HomeHeroCard(
                week: week,
                todayCourseCount: todayCourses.length,
                onOpenSchedule: onOpenSchedule,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: MetricTile(
                      label: AppStrings.courseCount,
                      value: '${store.courses.length}',
                      color: homeLavender,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MetricTile(
                      label: AppStrings.currentWeekLabel,
                      value: weekLabel(week),
                      color: homePink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SectionTitle(
                title: AppStrings.todayCourses,
                action: allTodayCourses.isEmpty
                    ? null
                    : AppStrings.viewSchedule,
                onAction: allTodayCourses.isEmpty ? null : onOpenSchedule,
              ),
              const SizedBox(height: 10),
              if (todayCourses.isEmpty)
                EmptyTodayCard(message: todayStatusText)
              else
                for (final course in todayCourses)
                  TodayCourseTile(course: course, settings: settings),
            ],
          ),
        ),
      ],
    );
  }
}

/// 课程是否还没结束（当天已上完的课不再展示）。
bool isCourseNotFinished(
  AppSettingsModel settings,
  Course course,
  DateTime now,
) {
  final endMinute = minuteForLesson(settings, course.endLesson);
  if (endMinute == null) {
    return true;
  }
  final currentMinute = now.hour * 60 + now.minute;
  return currentMinute <= endMinute;
}

/// 第 [lesson] 节的下课时刻（当天分钟数）；无法计算时返回 null。
int? minuteForLesson(AppSettingsModel settings, int lesson) {
  final index = lesson - 1;
  if (index < 0 || index >= settings.startTimes.length) {
    return null;
  }
  final raw = settings.startTimes[index].trim().replaceAll('：', ':');
  if (raw.isEmpty) {
    return null;
  }
  final parts = raw.split(':');
  if (parts.length != 2) {
    return null;
  }
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) {
    return null;
  }
  if (hour < 0 || hour > 24 || minute < 0 || minute > 59) {
    return null;
  }
  if (hour == 24 && minute != 0) {
    return null;
  }
  return hour * 60 + minute + settings.durationPerLesson;
}

/// 通用卡片容器：白底、圆角、柔和阴影。首页多处复用。
class SoftPanel extends StatelessWidget {
  const SoftPanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: homePanel.withAlpha(238),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 1.4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x160b0550),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class HomeHeroCard extends StatelessWidget {
  const HomeHeroCard({
    required this.week,
    required this.todayCourseCount,
    required this.onOpenSchedule,
    super.key,
  });

  final int week;
  final int todayCourseCount;
  final VoidCallback onOpenSchedule;

  @override
  Widget build(BuildContext context) {
    return SoftPanel(
      padding: const EdgeInsets.fromLTRB(18, 16, 6, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppStrings.homeHeroTitle,
                  style: TextStyle(
                    color: homeInk,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.homeHeroSubtitle(
                    weekLabel(week),
                    todayCourseCount,
                  ),
                  style: const TextStyle(
                    color: homeMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: homeLavender,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onPressed: onOpenSchedule,
                  child: const Text(AppStrings.openSchedule),
                ),
              ],
            ),
          ),
          Image.asset(
            'assets/nav/nav_home_active.png',
            width: 142,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ],
      ),
    );
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile({
    required this.label,
    required this.value,
    required this.color,
    super.key,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SoftPanel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: homeMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    required this.title,
    this.action,
    this.onAction,
    super.key,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: homeInk,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    );
  }
}

class EmptyTodayCard extends StatelessWidget {
  const EmptyTodayCard({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SoftPanel(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Image.asset(
            'assets/nav/nav_schedule_idle.png',
            width: 74,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: homeInk,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TodayCourseTile extends StatelessWidget {
  const TodayCourseTile({
    required this.course,
    required this.settings,
    super.key,
  });

  final Course course;
  final AppSettingsModel settings;

  @override
  Widget build(BuildContext context) {
    final color = ScheduleUtils.colorForCourse(course);
    final time = ScheduleUtils.timeRange(settings, course);
    return SoftPanel(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 54,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: homeInk,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  [
                    lessonRangeLabel(course.startLesson, course.endLesson),
                    if (time.isNotEmpty) time,
                    if (course.location.isNotEmpty) course.location,
                  ].join(' / '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: homeMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
