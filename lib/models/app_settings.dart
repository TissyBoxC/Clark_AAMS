class AppSettingsModel {
  const AppSettingsModel({
    required this.maxWeeks,
    required this.durationPerLesson,
    required this.isFirstLaunch,
    required this.startTimes,
    required this.termMonth,
    required this.termDay,
    required this.termStartDate,
    required this.reminderTime,
    required this.remindWay,
    required this.alarmWay,
    required this.schoolId,
  });

  static const defaults = AppSettingsModel(
    maxWeeks: 18,
    durationPerLesson: 45,
    isFirstLaunch: true,
    startTimes: <String>[
      '8:00',
      '8:50',
      '9:50',
      '10:40',
      '11:30',
      '14:00',
      '14:50',
      '15:50',
      '16:40',
      '17:30',
      '19:00',
      '19:50',
      '20:40',
    ],
    termMonth: 9,
    termDay: 1,
    termStartDate: '',
    reminderTime: 10,
    remindWay: 1,
    alarmWay: 0,
    schoolId: '',
  );

  final int maxWeeks;
  final int durationPerLesson;
  final bool isFirstLaunch;
  final List<String> startTimes;
  final int termMonth;
  final int termDay;
  final String termStartDate;
  final int reminderTime;
  final int remindWay;
  final int alarmWay;
  final String schoolId;

  AppSettingsModel copyWith({
    int? maxWeeks,
    int? durationPerLesson,
    bool? isFirstLaunch,
    List<String>? startTimes,
    int? termMonth,
    int? termDay,
    String? termStartDate,
    int? reminderTime,
    int? remindWay,
    int? alarmWay,
    String? schoolId,
  }) {
    return AppSettingsModel(
      maxWeeks: maxWeeks ?? this.maxWeeks,
      durationPerLesson: durationPerLesson ?? this.durationPerLesson,
      isFirstLaunch: isFirstLaunch ?? this.isFirstLaunch,
      startTimes: startTimes ?? this.startTimes,
      termMonth: termMonth ?? this.termMonth,
      termDay: termDay ?? this.termDay,
      termStartDate: termStartDate ?? this.termStartDate,
      reminderTime: reminderTime ?? this.reminderTime,
      remindWay: remindWay ?? this.remindWay,
      alarmWay: alarmWay ?? this.alarmWay,
      schoolId: schoolId ?? this.schoolId,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'maxWeeks': maxWeeks,
      'durationPerLesson': durationPerLesson,
      'isFirstLaunch': isFirstLaunch,
      'startTimes': startTimes,
      'termMonth': termMonth,
      'termDay': termDay,
      'termStartDate': termStartDate,
      'reminderTime': reminderTime,
      'remindWay': remindWay,
      'alarmWay': alarmWay,
      'schoolId': schoolId,
    };
  }

  static AppSettingsModel fromJson(Map<String, Object?> json) {
    final defaults = AppSettingsModel.defaults;
    final rawStartTimes = json['startTimes'];
    return defaults.copyWith(
      maxWeeks: _asInt(json['maxWeeks']) ?? defaults.maxWeeks,
      durationPerLesson:
          _asInt(json['durationPerLesson']) ?? defaults.durationPerLesson,
      isFirstLaunch: json['isFirstLaunch'] as bool? ?? defaults.isFirstLaunch,
      startTimes: rawStartTimes is List
          ? rawStartTimes.whereType<String>().toList()
          : defaults.startTimes,
      termMonth: _asInt(json['termMonth']) ?? defaults.termMonth,
      termDay: _asInt(json['termDay']) ?? defaults.termDay,
      termStartDate:
          json['termStartDate'] as String? ??
          _legacyTermStartDate(json, defaults),
      reminderTime: _asInt(json['reminderTime']) ?? defaults.reminderTime,
      remindWay: _asInt(json['remindWay']) ?? defaults.remindWay,
      alarmWay: _asInt(json['alarmWay']) ?? defaults.alarmWay,
      schoolId: json['schoolId'] as String? ?? defaults.schoolId,
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

  static String _legacyTermStartDate(
    Map<String, Object?> json,
    AppSettingsModel defaults,
  ) {
    return '';
  }
}
