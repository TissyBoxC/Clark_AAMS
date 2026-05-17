import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../models/course.dart';

class ScheduleUtils {
  static const dayLabels = <String>['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  static const remindWays = <String>['日历日程', '闹钟', '通知'];
  static const alarmWays = <String>['需要确认', '直接设置'];

  static const courseColors = <Color>[
    Color(0xff2563eb),
    Color(0xff0891b2),
    Color(0xff059669),
    Color(0xff65a30d),
    Color(0xffca8a04),
    Color(0xffea580c),
    Color(0xffdc2626),
    Color(0xffe11d48),
    Color(0xffc026d3),
    Color(0xff7c3aed),
    Color(0xff4f46e5),
    Color(0xff0f766e),
    Color(0xff16a34a),
    Color(0xff84cc16),
    Color(0xfff59e0b),
    Color(0xfff97316),
    Color(0xffef4444),
    Color(0xfff43f5e),
    Color(0xffd946ef),
    Color(0xff8b5cf6),
    Color(0xff6366f1),
    Color(0xff0284c7),
    Color(0xff14b8a6),
    Color(0xff22c55e),
    Color(0xffa16207),
    Color(0xffb45309),
    Color(0xffbe123c),
    Color(0xff9333ea),
    Color(0xff475569),
    Color(0xff334155),
  ];

  static String localDateLabel(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }

  static DateTime termStartDate(AppSettingsModel settings) {
    final parsed = DateTime.tryParse(settings.termStartDate);
    if (parsed != null) {
      return DateTime(parsed.year, parsed.month, parsed.day);
    }
    final today = DateTime.now();
    return DateTime(today.year, today.month, today.day);
  }

  static int currentWeek(AppSettingsModel settings, DateTime today) {
    if (settings.termStartDate.isEmpty) {
      return 1;
    }
    final monday = termStartDate(settings);
    final diff = DateTime(
      today.year,
      today.month,
      today.day,
    ).difference(monday).inDays;
    return (diff ~/ 7 + 1).clamp(1, settings.maxWeeks);
  }

  static DateTime weekMonday(AppSettingsModel settings, int week) {
    return termStartDate(settings).add(Duration(days: (week - 1) * 7));
  }

  static String formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static String timeRange(AppSettingsModel settings, Course course) {
    if (course.startLesson < 1 ||
        course.endLesson < 1 ||
        course.startLesson > settings.startTimes.length ||
        course.endLesson > settings.startTimes.length) {
      return '';
    }
    final start = settings.startTimes[course.startLesson - 1];
    final endStart = settings.startTimes[course.endLesson - 1];
    if (start.trim().isEmpty || endStart.trim().isEmpty) {
      return '';
    }
    final end = endTime(endStart, settings.durationPerLesson);
    return '$start-$end';
  }

  static int lessonCount(AppSettingsModel settings, [List<Course>? courses]) {
    var count = settings.startTimes.length;
    if (courses != null) {
      for (final course in courses) {
        if (course.endLesson > count) {
          count = course.endLesson;
        }
      }
    }
    return count.clamp(13, 30);
  }

  static String endTime(String startTime, int durationMinutes) {
    final parts = startTime.split(':');
    if (parts.length < 2) {
      return startTime;
    }
    var hour = int.tryParse(parts[0]) ?? 0;
    var minute = int.tryParse(parts[1]) ?? 0;
    minute += durationMinutes;
    hour = (hour + minute ~/ 60) % 24;
    minute = minute % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  static Color colorForCourse(Course course) {
    if (course.colorValue != null) {
      return Color(course.colorValue!);
    }
    return defaultColorForName(course.name);
  }

  static Color defaultColorForName(String name) {
    final hash = name.hashCode & 0x7fffffff;
    return courseColors[hash % courseColors.length];
  }

  static bool isTimeListValid(List<String> times) {
    if (times.isEmpty) {
      return false;
    }
    for (final time in times) {
      final parts = time.replaceAll('：', ':').split(':');
      if (parts.length != 2) {
        return false;
      }
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null ||
          minute == null ||
          hour < 0 ||
          hour > 24 ||
          minute < 0 ||
          minute > 59) {
        return false;
      }
      if (hour == 24 && minute != 0) {
        return false;
      }
    }
    return true;
  }
}
