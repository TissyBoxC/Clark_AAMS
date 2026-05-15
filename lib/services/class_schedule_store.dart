import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import '../models/course.dart';

class ClassScheduleStore extends ChangeNotifier {
  ClassScheduleStore._(this._prefs, this.settings, this._courses);

  static const _settingsKey = 'class_schedule_settings';
  static const _coursesKey = 'class_schedule_courses';
  static const _nextCourseIdKey = 'class_schedule_next_course_id';

  final SharedPreferences _prefs;
  AppSettingsModel settings;
  List<Course> _courses;

  List<Course> get courses {
    final sorted = [..._courses]
      ..sort((a, b) {
        final day = a.dayOfWeek.compareTo(b.dayOfWeek);
        if (day != 0) {
          return day;
        }
        return a.startLesson.compareTo(b.startLesson);
      });
    return sorted;
  }

  static Future<ClassScheduleStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString(_settingsKey);
    final coursesJson = prefs.getString(_coursesKey);

    var settings = AppSettingsModel.defaults;
    if (settingsJson != null) {
      final decoded = jsonDecode(settingsJson);
      if (decoded is Map<String, Object?>) {
        settings = AppSettingsModel.fromJson(decoded);
      } else if (decoded is Map) {
        settings = AppSettingsModel.fromJson(decoded.cast<String, Object?>());
      }
    }

    final courses = <Course>[];
    if (coursesJson != null) {
      final decoded = jsonDecode(coursesJson);
      if (decoded is List) {
        for (var index = 0; index < decoded.length; index++) {
          final item = decoded[index];
          if (item is Map<String, Object?>) {
            courses.add(Course.fromJson(item, fallbackId: index + 1));
          } else if (item is Map) {
            courses.add(
              Course.fromJson(
                item.cast<String, Object?>(),
                fallbackId: index + 1,
              ),
            );
          }
        }
      }
    }

    if (settings.hasSpecificSchool &&
        !settings.isFirstLaunch &&
        courses.isEmpty &&
        settings.termStartDate.isEmpty) {
      settings = settings.copyWith(schoolId: '', isFirstLaunch: true);
      await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
    }

    return ClassScheduleStore._(prefs, settings, courses);
  }

  Future<void> markLaunched() async {
    settings = settings.copyWith(isFirstLaunch: false);
    await _saveSettings();
  }

  Future<void> selectSchool(String schoolId) async {
    settings = settings.copyWith(
      schoolId: schoolId,
      isFirstLaunch: schoolId.isEmpty
          ? true
          : _courses.isNotEmpty
          ? false
          : settings.isFirstLaunch,
    );
    await _saveSettings();
  }

  Future<void> useOtherImportMethods() async {
    settings = settings.copyWith(
      schoolId: AppSettingsModel.unspecifiedSchoolId,
      isFirstLaunch: false,
    );
    await _saveSettings();
  }

  Future<void> resetSchoolSelection() async {
    await clearCourses();
    settings = settings.copyWith(schoolId: '', isFirstLaunch: true);
    await _saveSettings();
  }

  Future<void> updateSettings(AppSettingsModel next) async {
    settings = next;
    await _saveSettings();
  }

  Future<void> resetSettings() async {
    await clearCourses();
    settings = AppSettingsModel.defaults;
    await _saveSettings();
  }

  Future<void> clearCourses() async {
    _courses = const <Course>[];
    await _prefs.remove(_coursesKey);
    await _prefs.remove(_nextCourseIdKey);
    notifyListeners();
  }

  Future<void> addCourse(Course course) async {
    final id = _nextCourseId();
    _courses = [..._courses, course.copyWith(id: id)];
    await _saveCourses();
  }

  Future<void> importCourses(List<Course> courses) async {
    final next = [..._courses];
    for (final course in courses) {
      next.add(course.copyWith(id: _nextCourseId()));
    }
    _courses = next;
    await _saveCourses();
  }

  Future<void> updateCourse(int id, Course course) async {
    _courses = [
      for (final existing in _courses)
        if (existing.id == id) course.copyWith(id: id) else existing,
    ];
    await _saveCourses();
  }

  Future<void> deleteCourse(int id) async {
    _courses = _courses.where((course) => course.id != id).toList();
    await _saveCourses();
  }

  Future<void> deleteCourses(Set<int> ids) async {
    _courses = _courses.where((course) => !ids.contains(course.id)).toList();
    await _saveCourses();
  }

  Future<void> syncMaxWeeks({
    required int oldMaxWeeks,
    required int newMaxWeeks,
    required bool expandWholeTermCourses,
  }) async {
    _courses = [
      for (final course in _courses)
        if (newMaxWeeks > oldMaxWeeks &&
            expandWholeTermCourses &&
            course.endWeek == oldMaxWeeks)
          course.copyWith(
            endWeek: newMaxWeeks,
            activeWeeks: course.activeWeeks.isEmpty
                ? course.activeWeeks
                : [
                    ...course.activeWeeks,
                    for (
                      var week = oldMaxWeeks + 1;
                      week <= newMaxWeeks;
                      week++
                    )
                      week,
                  ],
          )
        else if (newMaxWeeks < oldMaxWeeks && course.endWeek > newMaxWeeks)
          course.copyWith(
            endWeek: newMaxWeeks,
            activeWeeks: course.activeWeeks
                .where((week) => week <= newMaxWeeks)
                .toList(),
          )
        else
          course,
    ];
    await _saveCourses();
  }

  String exportCoursesJson() {
    final sorted = courses
        .map((course) => course.toJson(includeId: false))
        .toList();
    return const JsonEncoder.withIndent('  ').convert(sorted);
  }

  Future<void> _saveSettings() async {
    await _prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
    notifyListeners();
  }

  Future<void> _saveCourses() async {
    await _prefs.setString(
      _coursesKey,
      jsonEncode(_courses.map((course) => course.toJson()).toList()),
    );
    notifyListeners();
  }

  int _nextCourseId() {
    final nextId = _prefs.getInt(_nextCourseIdKey) ?? 1;
    _prefs.setInt(_nextCourseIdKey, nextId + 1);
    return nextId;
  }
}
