import 'dart:convert';

import '../models/course.dart';

class CourseJsonImporter {
  const CourseJsonImporter._();

  static List<Course> parse(String jsonText) {
    final decoded = jsonDecode(jsonText);
    if (decoded is! List) {
      throw const FormatException('课程 JSON 必须是数组');
    }

    final courses = <Course>[];
    for (var index = 0; index < decoded.length; index++) {
      final item = decoded[index];
      if (item is! Map) {
        throw FormatException('第 ${index + 1} 门课程不是对象');
      }

      final course = Course.fromJson(
        item.cast<String, Object?>(),
        fallbackId: index + 1,
      );
      if (course.name.isEmpty ||
          course.dayOfWeek < 1 ||
          course.dayOfWeek > 7 ||
          course.startLesson < 1 ||
          course.endLesson < course.startLesson) {
        throw FormatException('第 ${index + 1} 门课程字段不完整');
      }
      courses.add(course);
    }

    return courses;
  }
}
