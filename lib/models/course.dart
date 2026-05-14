class Course {
  const Course({
    required this.id,
    required this.name,
    required this.startWeek,
    required this.endWeek,
    required this.dayOfWeek,
    required this.startLesson,
    required this.endLesson,
    required this.location,
    this.teacher = '',
    this.rawTime = '',
    this.activeWeeks = const <int>[],
    this.colorValue,
  });

  final int id;
  final String name;
  final int startWeek;
  final int endWeek;
  final int dayOfWeek;
  final int startLesson;
  final int endLesson;
  final String location;
  final String teacher;
  final String rawTime;
  final List<int> activeWeeks;
  final int? colorValue;

  int get duration => endLesson - startLesson + 1;

  String get weekText {
    if (activeWeeks.isEmpty) {
      return '$startWeek-$endWeek周';
    }
    if (activeWeeks.length == endWeek - startWeek + 1) {
      return '$startWeek-$endWeek周';
    }
    return '${activeWeeks.join(',')}周';
  }

  bool matchesWeek(int week) {
    if (activeWeeks.isNotEmpty) {
      return activeWeeks.contains(week);
    }
    return week >= startWeek && week <= endWeek;
  }

  Course copyWith({
    int? id,
    String? name,
    int? startWeek,
    int? endWeek,
    int? dayOfWeek,
    int? startLesson,
    int? endLesson,
    String? location,
    String? teacher,
    String? rawTime,
    List<int>? activeWeeks,
    int? colorValue,
  }) {
    return Course(
      id: id ?? this.id,
      name: name ?? this.name,
      startWeek: startWeek ?? this.startWeek,
      endWeek: endWeek ?? this.endWeek,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startLesson: startLesson ?? this.startLesson,
      endLesson: endLesson ?? this.endLesson,
      location: location ?? this.location,
      teacher: teacher ?? this.teacher,
      rawTime: rawTime ?? this.rawTime,
      activeWeeks: activeWeeks ?? this.activeWeeks,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  Map<String, Object?> toJson({bool includeId = true}) {
    return <String, Object?>{
      if (includeId) 'id': id,
      'name': name,
      'startWeek': startWeek,
      'endWeek': endWeek,
      'dayOfWeek': dayOfWeek,
      'startLesson': startLesson,
      'endLesson': endLesson,
      'location': location,
      'teacher': teacher,
      'rawTime': rawTime,
      'weeks': activeWeeks,
      if (colorValue != null) 'colorValue': colorValue,
    };
  }

  static Course fromJson(Map<String, Object?> json, {int? fallbackId}) {
    final activeWeeks = _asIntList(json['weeks']);
    return Course(
      id: _asInt(json['id']) ?? fallbackId ?? 0,
      name: (json['name'] as String? ?? '').trim(),
      startWeek:
          _asInt(json['startWeek']) ??
          (activeWeeks.isNotEmpty ? activeWeeks.first : 1),
      endWeek:
          _asInt(json['endWeek']) ??
          (activeWeeks.isNotEmpty ? activeWeeks.last : 1),
      dayOfWeek: _asInt(json['dayOfWeek']) ?? _asInt(json['day']) ?? 1,
      startLesson:
          _asInt(json['startLesson']) ?? _asInt(json['startSection']) ?? 1,
      endLesson: _asInt(json['endLesson']) ?? _asInt(json['endSection']) ?? 1,
      location:
          (json['location'] as String? ?? json['position'] as String? ?? '')
              .trim(),
      teacher: (json['teacher'] as String? ?? '').trim(),
      rawTime: (json['rawTime'] as String? ?? '').trim(),
      activeWeeks: activeWeeks,
      colorValue: _asInt(json['colorValue']),
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

  static List<int> _asIntList(Object? value) {
    if (value is List) {
      return value.map(_asInt).whereType<int>().toSet().toList()..sort();
    }
    return const <int>[];
  }
}
