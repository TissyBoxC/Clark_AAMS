import '../resources/app_strings.dart';

/// 单双周规则，与后端 `WeekPattern.Rule` 一一对应。
enum WeekRule {
  all,
  odd,
  even;

  /// 解析线格式的单双周标记。
  ///
  /// 服务端与 App 都输出大写，但历史数据、手工编辑的 JSON、
  /// 以及第三方导入源可能出现小写或带空白，这里统一做规范化，
  /// 否则「odd」会被静默当成全周——错得不明显但结果全错。
  static WeekRule fromWire(Object? value) {
    final normalized = value?.toString().trim().toUpperCase();
    if (normalized == 'ODD') {
      return WeekRule.odd;
    }
    if (normalized == 'EVEN') {
      return WeekRule.even;
    }
    return WeekRule.all;
  }

  String get wire {
    switch (this) {
      case WeekRule.all:
        return 'ALL';
      case WeekRule.odd:
        return 'ODD';
      case WeekRule.even:
        return 'EVEN';
    }
  }
}

/// 连续周次区间，闭区间语义。
class WeekRange {
  const WeekRange(this.start, this.end);

  final int start;
  final int end;

  int get length => end - start + 1;

  Map<String, Object?> toJson() => <String, Object?>{
    'start': start,
    'end': end,
  };

  static WeekRange? fromJson(Object? value) {
    if (value is List && value.length >= 2) {
      final start = _asInt(value[0]);
      final end = _asInt(value[1]);
      if (start != null && end != null) {
        return WeekRange(start, end);
      }
      return null;
    }
    if (value is Map) {
      final start = _asInt(value['start']);
      final end = _asInt(value['end']);
      if (start != null && end != null) {
        return WeekRange(start, end);
      }
    }
    return null;
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is WeekRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => '$start-$end';
}

/// 周次规则：区间 + 单双周。这是 App 端的唯一真相源。
///
/// 与后端 `WeekPattern` 保持同一建模，避免「展开数组」与「首末周」
/// 两套字段互相矛盾（例如 `1-3,5-16` 被压成 `1..16`、`1-16(单)` 被压成 `1..15`）。
class WeekPattern {
  const WeekPattern({required this.ranges, this.rule = WeekRule.all});

  final List<WeekRange> ranges;
  final WeekRule rule;

  static const WeekPattern empty = WeekPattern(ranges: <WeekRange>[]);

  bool get isEmpty => expand().isEmpty;

  /// 周次上限。超过这个值的周次在任何环节都不应出现。
  static const int maxWeek = 30;

  /// 展开为升序离散周次。
  ///
  /// 越界周次在这里统一裁掉：`fromWeeks` 会在入口过滤，
  /// 但直接构造的 `WeekPattern`（如后端返回 `[25,40]`）也必须有防线，
  /// 否则「第 40 周」会渗到周视图与今日视图里。
  List<int> expand() {
    final result = <int>{};
    for (final range in ranges) {
      final from = range.start < 1 ? 1 : range.start;
      final to = range.end > maxWeek ? maxWeek : range.end;
      for (var week = from; week <= to; week++) {
        if (rule == WeekRule.odd && week.isEven) continue;
        if (rule == WeekRule.even && week.isOdd) continue;
        result.add(week);
      }
    }
    final list = result.toList()..sort();
    return list;
  }

  int? get firstWeek {
    final weeks = expand();
    return weeks.isEmpty ? null : weeks.first;
  }

  int? get lastWeek {
    final weeks = expand();
    return weeks.isEmpty ? null : weeks.last;
  }

  /// 从离散周次反推（兼容旧数据 / 只给 weeks 的后端）。
  static WeekPattern fromWeeks(List<int> weeks) {
    final sorted = weeks.where((w) => w >= 1 && w <= 30).toSet().toList()
      ..sort();
    if (sorted.isEmpty) {
      return WeekPattern.empty;
    }

    // 纯奇数 => 单周，纯偶数 => 双周；单元素不判定
    var rule = WeekRule.all;
    if (sorted.length > 1) {
      if (sorted.every((w) => w.isOdd)) {
        rule = WeekRule.odd;
      } else if (sorted.every((w) => w.isEven)) {
        rule = WeekRule.even;
      }
    }

    final ranges = <WeekRange>[];
    // 判定出单/双周后，区间按步长 2 合并：[1,3,5,7] => [1,7]+ODD，
    // 展示为「1-7周(单)」。expand() 会按 rule 过滤，语义等价。
    final step = rule == WeekRule.all ? 1 : 2;
    var start = sorted.first;
    var prev = start;
    for (var i = 1; i < sorted.length; i++) {
      final current = sorted[i];
      if (current == prev + step) {
        prev = current;
        continue;
      }
      ranges.add(WeekRange(start, prev));
      start = current;
      prev = current;
    }
    ranges.add(WeekRange(start, prev));
    return WeekPattern(ranges: ranges, rule: rule);
  }

  /// 展示文本，例如 `1-3,5-16周(单)`。
  String get text {
    if (ranges.isEmpty) return '';
    final buffer = StringBuffer();
    for (final range in ranges) {
      if (buffer.isNotEmpty) buffer.write(',');
      if (range.start == range.end) {
        buffer.write(range.start);
      } else {
        buffer.write('${range.start}-${range.end}');
      }
    }
    buffer.write('周');
    if (rule == WeekRule.odd) buffer.write(AppStrings.weekRuleOddSuffix);
    if (rule == WeekRule.even) buffer.write(AppStrings.weekRuleEvenSuffix);
    return buffer.toString();
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'weekRanges': ranges.map((r) => <int>[r.start, r.end]).toList(),
    'weekRule': rule.wire,
  };

  /// 解析后端返回的周次信息；缺字段时退化为 `fromWeeks`。
  static WeekPattern fromJson(Map<String, Object?> json) {
    final raw = json['weekRanges'];
    if (raw is List) {
      final ranges = raw
          .map(WeekRange.fromJson)
          .whereType<WeekRange>()
          .where((r) => r.start >= 1 && r.end <= 30 && r.end >= r.start)
          .toList();
      if (ranges.isNotEmpty) {
        return WeekPattern(
          ranges: ranges,
          rule: WeekRule.fromWire(json['weekRule']),
        );
      }
    }
    return WeekPattern.fromWeeks(Course.weeksOf(json['weeks']));
  }
}

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
    this.weekPattern = WeekPattern.empty,
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

  /// 周次唯一真相源。`startWeek`/`endWeek` 由它派生，仅为兼容保留。
  final WeekPattern weekPattern;

  final int? colorValue;

  /// 展开后的周次（由 weekPattern 派生，不再单独存储）。
  List<int> get activeWeeks => weekPattern.expand();

  int get duration => endLesson - startLesson + 1;

  String get weekText {
    if (weekPattern.ranges.isEmpty) {
      return AppStrings.weekRangeText(startWeek, endWeek);
    }
    return weekPattern.text;
  }

  /// 该课程是否在指定周上课。唯一判定依据是 weekPattern，
  /// 不再回退到 `startWeek..endWeek` 区间（那会把单双周与断档周算错）。
  bool matchesWeek(int week) {
    if (weekPattern.ranges.isEmpty) {
      return week >= startWeek && week <= endWeek;
    }
    return activeWeeks.contains(week);
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
    WeekPattern? weekPattern,
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
      weekPattern: weekPattern ?? this.weekPattern,
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
      // 真相源一并写出，便于三端对齐与排错
      ...weekPattern.toJson(),
      if (colorValue != null) 'colorValue': colorValue,
    };
  }

  static Course fromJson(Map<String, Object?> json, {int? fallbackId}) {
    final pattern = WeekPattern.fromJson(json);
    final weeks = pattern.expand();
    return Course(
      id: _asInt(json['id']) ?? fallbackId ?? 0,
      name: (json['name'] as String? ?? '').trim(),
      startWeek:
          pattern.firstWeek ??
          _asInt(json['startWeek']) ??
          (weeks.isNotEmpty ? weeks.first : 1),
      endWeek:
          pattern.lastWeek ??
          _asInt(json['endWeek']) ??
          (weeks.isNotEmpty ? weeks.last : 1),
      dayOfWeek: _asInt(json['dayOfWeek']) ?? _asInt(json['day']) ?? 1,
      startLesson:
          _asInt(json['startLesson']) ?? _asInt(json['startSection']) ?? 1,
      endLesson: _asInt(json['endLesson']) ?? _asInt(json['endSection']) ?? 1,
      location:
          (json['location'] as String? ?? json['position'] as String? ?? '')
              .trim(),
      teacher: (json['teacher'] as String? ?? '').trim(),
      rawTime: (json['rawTime'] as String? ?? '').trim(),
      weekPattern: pattern,
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

  static List<int> weeksOf(Object? value) {
    if (value is List) {
      return value.map(_asInt).whereType<int>().toSet().toList()..sort();
    }
    return const <int>[];
  }
}
