import '../models/course.dart';
import '../models/school_lesson_times.dart';
import '../resources/app_strings.dart';
import 'clark_backend_api.dart';
import 'class_schedule_store.dart';
import 'schedule_utils.dart';

class LessonTimeSetupDefaults {
  const LessonTimeSetupDefaults({
    required this.initialStartTimes,
    required this.generalProfiles,
    required this.notice,
  });

  final List<String> initialStartTimes;
  final List<SchoolLessonTimes> generalProfiles;
  final String notice;
}

class LessonTimeDefaults {
  const LessonTimeDefaults._();

  static Future<LessonTimeSetupDefaults> resolve(
    ClassScheduleStore store, {
    List<Course>? courses,
  }) async {
    final lessonCount = ScheduleUtils.lessonCount(store.settings, courses);
    final localStartTimes = _fitLength(store.settings.startTimes, lessonCount);
    if (_hasConfiguredTimes(localStartTimes)) {
      return LessonTimeSetupDefaults(
        initialStartTimes: localStartTimes,
        generalProfiles: const <SchoolLessonTimes>[],
        notice: '',
      );
    }
    if (store.settings.hasSpecificSchool) {
      try {
        final schoolTimes = await ClarkBackendApi.instance.getSchoolLessonTimes(
          store.settings.schoolId,
        );
        return LessonTimeSetupDefaults(
          initialStartTimes: _fitLength(
            schoolTimes.toStartTimes(minimumLength: lessonCount),
            lessonCount,
          ),
          generalProfiles: const <SchoolLessonTimes>[],
          notice: AppStrings.lessonTimesImportedForSchool,
        );
      } catch (_) {
        return LessonTimeSetupDefaults(
          initialStartTimes: _fitLength(store.settings.startTimes, lessonCount),
          generalProfiles: const <SchoolLessonTimes>[],
          notice: AppStrings.lessonTimesSchoolFailed,
        );
      }
    }

    try {
      final profiles = await ClarkBackendApi.instance
          .getGeneralLessonTimeProfiles();
      final sorted = [...profiles]
        ..sort((a, b) {
          return a.firstConfiguredStartTime.compareTo(
            b.firstConfiguredStartTime,
          );
        });
      return LessonTimeSetupDefaults(
        initialStartTimes: _fitLength(store.settings.startTimes, lessonCount),
        generalProfiles: sorted,
        notice: AppStrings.lessonTimesNoSchool,
      );
    } catch (_) {
      return LessonTimeSetupDefaults(
        initialStartTimes: _fitLength(store.settings.startTimes, lessonCount),
        generalProfiles: const <SchoolLessonTimes>[],
        notice: AppStrings.lessonTimesGeneralFailed,
      );
    }
  }

  static List<String> _fitLength(List<String> value, int lessonCount) {
    return [
      for (var index = 0; index < lessonCount; index++)
        index < value.length ? value[index] : '',
    ];
  }

  static bool _hasConfiguredTimes(List<String> times) {
    return times.any((time) => time.trim().isNotEmpty);
  }
}
