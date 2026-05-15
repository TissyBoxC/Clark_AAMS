import 'package:flutter_test/flutter_test.dart';
import 'package:clark_aams/models/app_settings.dart';
import 'package:clark_aams/models/course.dart';
import 'package:clark_aams/services/course_json_importer.dart';
import 'package:clark_aams/services/schedule_utils.dart';

void main() {
  test('formats course time range from configured start times', () {
    const settings = AppSettingsModel.defaults;
    const course = Course(
      id: 1,
      name: '高等数学',
      startWeek: 1,
      endWeek: 18,
      dayOfWeek: 1,
      startLesson: 3,
      endLesson: 4,
      location: 'A101',
    );

    expect(ScheduleUtils.timeRange(settings, course), '9:50-11:25');
  });

  test('calculates current week from the first day of week one', () {
    final settings = AppSettingsModel.defaults.copyWith(
      termStartDate: '2026-03-02',
      maxWeeks: 18,
    );

    expect(ScheduleUtils.currentWeek(settings, DateTime(2026, 3, 2)), 1);
    expect(ScheduleUtils.currentWeek(settings, DateTime(2026, 3, 9)), 2);
    expect(ScheduleUtils.currentWeek(settings, DateTime(2026, 5, 15)), 11);
  });

  test('does not infer September first when term start is unset', () {
    final settings = AppSettingsModel.defaults.copyWith(termStartDate: '');

    expect(ScheduleUtils.currentWeek(settings, DateTime(2026, 5, 15)), 1);
  });

  test('serializes course JSON used by batch import and export', () {
    final course = Course.fromJson(const {
      'name': '英语',
      'startWeek': 1,
      'endWeek': 16,
      'dayOfWeek': 2,
      'startLesson': 1,
      'endLesson': 2,
      'location': 'B201',
    });

    expect(course.name, '英语');
    expect(course.toJson(includeId: false)['dayOfWeek'], 2);
  });

  test('parses backend course JSON into app course model', () {
    final courses = CourseJsonImporter.parse('''
[
  {
    "name": "面向对象程序设计",
    "teacher": "张三",
    "position": "1307（多媒体）",
    "day": 1,
    "startSection": 3,
    "endSection": 4,
    "weeks": [1, 3, 5],
    "rawTime": "3-4节 (1-5周单周)"
  }
]
''');

    expect(courses, hasLength(1));
    expect(courses.single.location, '1307（多媒体）');
    expect(courses.single.dayOfWeek, 1);
    expect(courses.single.startLesson, 3);
    expect(courses.single.endLesson, 4);
    expect(courses.single.activeWeeks, [1, 3, 5]);
    expect(courses.single.matchesWeek(3), isTrue);
    expect(courses.single.matchesWeek(4), isFalse);
  });
}
