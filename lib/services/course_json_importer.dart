import 'dart:convert';

import '../models/course.dart';
import '../resources/app_strings.dart';

class CourseJsonImporter {
  const CourseJsonImporter._();

  static List<Course> parse(String jsonText) {
    final decoded = jsonDecode(jsonText);
    if (decoded is! List) {
      throw const FormatException(AppStrings.courseJsonMustBeArray);
    }

    final courses = <Course>[];
    for (var index = 0; index < decoded.length; index++) {
      final item = decoded[index];
      if (item is! Map) {
        throw FormatException(AppStrings.courseJsonItemNotObject(index + 1));
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
        throw FormatException(AppStrings.courseJsonItemIncomplete(index + 1));
      }
      courses.add(course);
    }

    return courses;
  }
}
