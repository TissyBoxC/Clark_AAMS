import 'dart:convert';

import '../../models/course.dart';
import 'jit_jwxt_parser.dart';

class JitCourseImporter {
  const JitCourseImporter._();

  static List<Course> parse(String jsonText) {
    final decoded = jsonDecode(jsonText);
    if (decoded is! List) {
      throw const FormatException('课程 JSON 必须是数组');
    }

    final courses = <Course>[];
    for (var index = 0; index < decoded.length; index++) {
      final item = decoded[index];
      if (item is! Map) {
        throw FormatException('第 ${index + 1} 个课程不是对象');
      }

      final course = _parseCourse(item.cast<String, Object?>(), index + 1);
      if (course.name.isEmpty ||
          course.dayOfWeek < 1 ||
          course.dayOfWeek > 7 ||
          course.startLesson < 1 ||
          course.endLesson < course.startLesson) {
        throw FormatException('第 ${index + 1} 个课程字段不完整');
      }
      courses.add(course);
    }

    return courses;
  }

  static List<Course> parseRawCourses(List<JitJwxtRawCourse> rawCourses) {
    return parse(
      const JsonEncoder.withIndent(
        '  ',
      ).convert(rawCourses.map((course) => course.toJson()).toList()),
    );
  }

  static Course _parseCourse(Map<String, Object?> json, int fallbackId) {
    final weeks = _parseWeeks(json['weeks']);
    final startWeek =
        _asInt(json['startWeek']) ??
        (weeks.isNotEmpty ? weeks.first : _parseWeekRange(json['rawTime']).$1);
    final endWeek =
        _asInt(json['endWeek']) ??
        (weeks.isNotEmpty ? weeks.last : _parseWeekRange(json['rawTime']).$2);

    return Course(
      id: _asInt(json['id']) ?? fallbackId,
      name: (json['name'] as String? ?? '').trim(),
      teacher: (json['teacher'] as String? ?? '').trim(),
      location:
          (json['location'] as String? ?? json['position'] as String? ?? '')
              .trim(),
      startWeek: startWeek ?? 1,
      endWeek: endWeek ?? startWeek ?? 1,
      dayOfWeek: _asInt(json['dayOfWeek']) ?? _asInt(json['day']) ?? 1,
      startLesson:
          _asInt(json['startLesson']) ?? _asInt(json['startSection']) ?? 1,
      endLesson: _asInt(json['endLesson']) ?? _asInt(json['endSection']) ?? 1,
      rawTime: (json['rawTime'] as String? ?? '').trim(),
      activeWeeks: weeks,
    );
  }

  static List<int> _parseWeeks(Object? value) {
    if (value is! List) {
      return const <int>[];
    }
    return value.map(_asInt).whereType<int>().toSet().toList()..sort();
  }

  static (int?, int?) _parseWeekRange(Object? value) {
    if (value is! String) {
      return (null, null);
    }
    final match = RegExp(r'(\d+)\s*[-~至]\s*(\d+)\s*周').firstMatch(value);
    if (match == null) {
      return (null, null);
    }
    return (int.tryParse(match.group(1)!), int.tryParse(match.group(2)!));
  }

  static int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }
}
