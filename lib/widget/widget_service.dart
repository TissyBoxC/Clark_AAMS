// ignore_for_file: unnecessary_brace_in_string_interps

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import '../models/course.dart';
import '../services/schedule_utils.dart';

class WidgetService {
  WidgetService._();

  static const _widgetDataKey = 'course_widget_payload';
  static const _settingsKey = 'class_schedule_settings';
  static const _coursesKey = 'class_schedule_courses';
  static const _androidWidgetName =
      'io.github.tissyboxc.widget.WidgetUpdateReceiver';

  static Future<void> updateWidget() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    final payload = await _buildPayload();
    try {
      await HomeWidget.saveWidgetData<String>(
        _widgetDataKey,
        jsonEncode(payload.toJson()),
      );
      await HomeWidget.updateWidget(qualifiedAndroidName: _androidWidgetName);
    } catch (_) {
      // Widget sync is best-effort and must not block local data saves.
    }
  }

  static Future<bool> pinWidget() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }

    try {
      final supported = await HomeWidget.isRequestPinWidgetSupported() ?? false;
      if (!supported) {
        return false;
      }
      await HomeWidget.requestPinWidget(
        qualifiedAndroidName: _androidWidgetName,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<_WidgetPayload> _buildPayload() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settings = _readSettings(prefs);
      final courses = _readCourses(prefs);
      return _WidgetPayload(
        small: _buildSmallState(settings, courses),
        medium: _buildMediumState(settings, courses),
      );
    } catch (_) {
      return const _WidgetPayload(
        small: _WidgetPanelState(
          status: _WidgetStatus.error,
          message: '数据同步失败',
        ),
        medium: _WidgetPanelState(
          status: _WidgetStatus.error,
          message: '数据同步失败',
        ),
      );
    }
  }

  static AppSettingsModel _readSettings(SharedPreferences prefs) {
    final raw = prefs.getString(_settingsKey);
    if (raw == null || raw.isEmpty) {
      return AppSettingsModel.defaults;
    }

    final decoded = jsonDecode(raw);
    if (decoded is Map<String, Object?>) {
      return AppSettingsModel.fromJson(decoded);
    }
    if (decoded is Map) {
      return AppSettingsModel.fromJson(decoded.cast<String, Object?>());
    }
    return AppSettingsModel.defaults;
  }

  static List<Course> _readCourses(SharedPreferences prefs) {
    final raw = prefs.getString(_coursesKey);
    if (raw == null || raw.isEmpty) {
      return const <Course>[];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const <Course>[];
    }

    final courses = <Course>[];
    for (var index = 0; index < decoded.length; index++) {
      final item = decoded[index];
      if (item is Map<String, Object?>) {
        courses.add(Course.fromJson(item, fallbackId: index + 1));
      } else if (item is Map) {
        courses.add(
          Course.fromJson(item.cast<String, Object?>(), fallbackId: index + 1),
        );
      }
    }
    courses.sort(_compareCourse);
    return courses;
  }

  static int _compareCourse(Course a, Course b) {
    final day = a.dayOfWeek.compareTo(b.dayOfWeek);
    if (day != 0) {
      return day;
    }
    return a.startLesson.compareTo(b.startLesson);
  }

  static _WidgetPanelState _buildSmallState(
    AppSettingsModel settings,
    List<Course> courses,
  ) {
    final today = DateTime.now();
    final todayCourses = _coursesForDate(settings, courses, today);
    if (todayCourses.isEmpty) {
      return const _WidgetPanelState(
        status: _WidgetStatus.empty,
        message: '今天暂无课程',
      );
    }

    if (!_hasUsableTime(todayCourses, settings)) {
      return const _WidgetPanelState(
        status: _WidgetStatus.missingTimes,
        message: '请先配置上课时间',
      );
    }

    final nextCourse = _nextCourse(todayCourses, settings, today);
    if (nextCourse == null) {
      return const _WidgetPanelState(
        status: _WidgetStatus.finished,
        message: '今日课程已结束',
      );
    }

    return _WidgetPanelState(
      status: _WidgetStatus.ready,
      nextCourse: _WidgetCourseView.fromCourse(
        settings: settings,
        course: nextCourse,
        now: today,
      ),
    );
  }

  static _WidgetPanelState _buildMediumState(
    AppSettingsModel settings,
    List<Course> courses,
  ) {
    final todayCourses = _coursesForDate(settings, courses, DateTime.now());
    if (todayCourses.isEmpty) {
      return const _WidgetPanelState(
        status: _WidgetStatus.empty,
        message: '今天暂无课程',
      );
    }

    if (!_hasUsableTime(todayCourses, settings)) {
      return const _WidgetPanelState(
        status: _WidgetStatus.missingTimes,
        message: '请先配置上课时间',
      );
    }

    return _WidgetPanelState(
      status: _WidgetStatus.ready,
      courseRows: [
        for (final course in todayCourses.take(4))
          _WidgetCourseRow.fromCourse(settings: settings, course: course),
      ],
    );
  }

  static List<Course> _coursesForDate(
    AppSettingsModel settings,
    List<Course> courses,
    DateTime date,
  ) {
    final week = ScheduleUtils.currentWeek(settings, date);
    final dayOfWeek = _appDayOfWeek(date);
    final todayCourses =
        courses
            .where(
              (course) =>
                  course.dayOfWeek == dayOfWeek && course.matchesWeek(week),
            )
            .toList()
          ..sort(_compareCourse);
    return todayCourses;
  }

  static Course? _nextCourse(
    List<Course> courses,
    AppSettingsModel settings,
    DateTime now,
  ) {
    final currentMinute = now.hour * 60 + now.minute;
    for (final course in courses) {
      final startMinute = _minuteForLesson(settings, course.startLesson);
      final endMinute = _minuteForLesson(settings, course.endLesson);
      if (startMinute == null || endMinute == null) {
        continue;
      }
      if (currentMinute <= endMinute) {
        return course;
      }
    }
    return null;
  }

  static bool _hasUsableTime(List<Course> courses, AppSettingsModel settings) {
    for (final course in courses) {
      if (_minuteForLesson(settings, course.startLesson) != null &&
          _minuteForLesson(settings, course.endLesson) != null) {
        return true;
      }
    }
    return false;
  }

  static int _appDayOfWeek(DateTime date) {
    return date.weekday == DateTime.sunday ? 7 : date.weekday;
  }

  static int? _minuteForLesson(AppSettingsModel settings, int lesson) {
    final index = lesson - 1;
    if (index < 0 || index >= settings.startTimes.length) {
      return null;
    }
    final raw = settings.startTimes[index].trim();
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
    return hour * 60 + minute;
  }
}

class _WidgetPayload {
  const _WidgetPayload({required this.small, required this.medium});

  final _WidgetPanelState small;
  final _WidgetPanelState medium;

  Map<String, Object?> toJson() => <String, Object?>{
    'small': small.toJson(),
    'medium': medium.toJson(),
  };
}

class _WidgetPanelState {
  const _WidgetPanelState({
    required this.status,
    this.message = '',
    this.nextCourse,
    this.courseRows = const <_WidgetCourseRow>[],
  });

  final _WidgetStatus status;
  final String message;
  final _WidgetCourseView? nextCourse;
  final List<_WidgetCourseRow> courseRows;

  Map<String, Object?> toJson() => <String, Object?>{
    'status': status.name,
    'message': message,
    if (nextCourse != null) 'nextCourse': nextCourse!.toJson(),
    if (courseRows.isNotEmpty)
      'courseRows': courseRows.map((row) => row.toJson()).toList(),
  };
}

enum _WidgetStatus { ready, empty, finished, missingTimes, error }

class _WidgetCourseView {
  const _WidgetCourseView({
    required this.name,
    required this.timeText,
    required this.roomText,
    required this.remainingText,
  });

  final String name;
  final String timeText;
  final String roomText;
  final String remainingText;

  factory _WidgetCourseView.fromCourse({
    required AppSettingsModel settings,
    required Course course,
    required DateTime now,
  }) {
    final startMinute = WidgetService._minuteForLesson(
      settings,
      course.startLesson,
    );
    final endMinute = WidgetService._minuteForLesson(
      settings,
      course.endLesson,
    );
    final startText = _formatMinute(startMinute);
    final endText = _formatMinute(endMinute);
    final timeText = startText.isEmpty || endText.isEmpty
        ? '时间未配置'
        : '$startText-$endText';

    final currentMinute = now.hour * 60 + now.minute;
    final targetMinute = startMinute != null && currentMinute < startMinute
        ? startMinute
        : endMinute ?? startMinute ?? 0;
    final remaining = targetMinute - currentMinute;
    final remainingText = remaining <= 0
        ? '已开始'
        : '剩余 ${_formatDuration(remaining)}';

    return _WidgetCourseView(
      name: course.name.isEmpty ? '未命名课程' : course.name,
      timeText: timeText,
      roomText: course.location.isEmpty ? '教室未填写' : course.location,
      remainingText: remainingText,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'name': name,
    'timeText': timeText,
    'roomText': roomText,
    'remainingText': remainingText,
  };
}

class _WidgetCourseRow {
  const _WidgetCourseRow({
    required this.name,
    required this.timeText,
    required this.roomText,
  });

  final String name;
  final String timeText;
  final String roomText;

  factory _WidgetCourseRow.fromCourse({
    required AppSettingsModel settings,
    required Course course,
  }) {
    final timeText = ScheduleUtils.timeRange(settings, course);
    return _WidgetCourseRow(
      name: course.name.isEmpty ? '未命名课程' : course.name,
      timeText: timeText.isEmpty ? '时间未配置' : timeText,
      roomText: course.location.isEmpty ? '教室未填写' : course.location,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'name': name,
    'timeText': timeText,
    'roomText': roomText,
  };
}

String _formatMinute(int? minute) {
  if (minute == null || minute < 0) {
    return '';
  }
  final hour = minute ~/ 60;
  final valueMinute = minute % 60;
  return '${hour.toString().padLeft(2, '0')}:${valueMinute.toString().padLeft(2, '0')}';
}

String _formatDuration(int minute) {
  final hours = minute ~/ 60;
  final remainingMinutes = minute % 60;
  if (hours <= 0) {
    return '${remainingMinutes}分钟';
  }
  if (remainingMinutes <= 0) {
    return '${hours}小时';
  }
  return '${hours}小时${remainingMinutes}分钟';
}
