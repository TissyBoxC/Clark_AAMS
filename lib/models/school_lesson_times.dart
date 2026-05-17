class LessonTime {
  const LessonTime({required this.lesson, required this.startTime});

  final int lesson;
  final String startTime;

  factory LessonTime.fromJson(Map<String, Object?> json) {
    return LessonTime(
      lesson: _asInt(json['lesson']) ?? 0,
      startTime: (json['startTime'] as String? ?? '').trim(),
    );
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

class SchoolLessonTimes {
  const SchoolLessonTimes({
    required this.schoolId,
    required this.profile,
    required this.lessons,
  });

  final String schoolId;
  final String profile;
  final List<LessonTime> lessons;

  factory SchoolLessonTimes.fromJson(Map<String, Object?> json) {
    final rawLessons = json['lessons'];
    return SchoolLessonTimes(
      schoolId: (json['schoolId'] as String? ?? '').trim(),
      profile: (json['profile'] as String? ?? '').trim(),
      lessons: rawLessons is List
          ? [
              for (final item in rawLessons)
                if (item is Map<String, Object?>)
                  LessonTime.fromJson(item)
                else if (item is Map)
                  LessonTime.fromJson(item.cast<String, Object?>()),
            ]
          : const <LessonTime>[],
    );
  }

  List<String> toStartTimes({int minimumLength = 13}) {
    var maxLesson = minimumLength;
    for (final lesson in lessons) {
      if (lesson.lesson > maxLesson) {
        maxLesson = lesson.lesson;
      }
    }
    final times = List<String>.filled(maxLesson, '');
    for (final lesson in lessons) {
      final index = lesson.lesson - 1;
      if (index >= 0 && index < times.length) {
        times[index] = lesson.startTime;
      }
    }
    return times;
  }

  String get firstConfiguredStartTime {
    for (final lesson in lessons) {
      if (lesson.startTime.isNotEmpty) {
        return lesson.startTime;
      }
    }
    return '';
  }
}
