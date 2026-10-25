import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import '../models/course.dart';
import '../utils/json_util.dart';
import '../widget/widget_service.dart';
import 'course_importer.dart';

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
    final settingsMap = JsonUtil.asMap(JsonUtil.tryDecode(settingsJson));
    if (settingsMap != null) {
      settings = AppSettingsModel.fromJson(settingsMap);
    }

    final courses = <Course>[];
    final courseMaps = JsonUtil.asMapList(JsonUtil.tryDecode(coursesJson));
    for (var index = 0; index < courseMaps.length; index++) {
      courses.add(Course.fromJson(courseMaps[index], fallbackId: index + 1));
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
    await WidgetService.updateWidget();
    notifyListeners();
  }

  Future<void> addCourse(Course course) async {
    final id = _nextCourseId();
    _courses = [..._courses, course.copyWith(id: id)];
    await _saveCourses();
  }

  /// 导入课程。
  ///
  /// 原实现是无条件追加，同一个课表连点两次导入课程数会翻倍（B7）。
  /// 现在按 [ImportMode] 去重：[ImportMode.merge] 为默认，
  /// 同名同时间同地点同周次的课程会被更新而非重复添加。
  Future<ImportOutcome> importCourses(
    List<Course> courses, {
    ImportMode mode = ImportMode.merge,
  }) async {
    final outcome = CourseImporter.apply(
      existing: _courses,
      incoming: courses,
      mode: mode,
      nextId: _nextCourseId,
    );
    _courses = outcome.courses;
    await _saveCourses();
    return outcome;
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
            weekPattern: WeekPattern.fromWeeks([
              ...course.activeWeeks,
              for (
                var week = oldMaxWeeks + 1;
                week <= newMaxWeeks;
                week++
              )
                week,
            ]),
          )
        else if (newMaxWeeks < oldMaxWeeks && course.endWeek > newMaxWeeks)
          course.copyWith(
            weekPattern: WeekPattern.fromWeeks(
              course.activeWeeks.where((week) => week <= newMaxWeeks).toList(),
            ),
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
    await WidgetService.updateWidget();
    notifyListeners();
  }

  Future<void> _saveCourses() async {
    await _prefs.setString(
      _coursesKey,
      jsonEncode(_courses.map((course) => course.toJson()).toList()),
    );
    await WidgetService.updateWidget();
    notifyListeners();
  }

  /// 分配下一个课程 id。
  ///
  /// 修复 B3：原实现只读 `_nextCourseIdKey`，但该键在重新加载、
  /// 删除后不会回退，若课程由 `fallbackId`（按数组下标）恢复、
  /// 或用户在别处清掉该键，就会发出与现有课程重复的 id，
  /// 导致 `updateCourse` / `deleteCourse` 一次命中多门课。
  ///
  /// 现在取「持久化计数器」与「现有最大 id + 1」的较大值，
  /// 保证新 id 恒大于全部已有 id。
  int _nextCourseId() {
    final stored = _prefs.getInt(_nextCourseIdKey) ?? 1;
    var maxExisting = 0;
    for (final course in _courses) {
      if (course.id > maxExisting) {
        maxExisting = course.id;
      }
    }
    final nextId = stored > maxExisting ? stored : maxExisting + 1;
    _prefs.setInt(_nextCourseIdKey, nextId + 1);
    return nextId;
  }
}
