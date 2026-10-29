import '../models/course.dart';

/// 导入时如何与已有课程合并。
enum ImportMode {
  /// 覆盖：用本次导入的结果整体替换现有课表。
  replace,

  /// 合并：同名同时间同地点的课程更新，其余保留（默认）。
  merge,

  /// 追加：无条件全部加入，不做去重。
  append;

  static ImportMode fromWire(Object? value) {
    switch (value) {
      case 'replace':
        return ImportMode.replace;
      case 'append':
        return ImportMode.append;
      default:
        return ImportMode.merge;
    }
  }
}

/// 导入结果统计，供 UI 展示「新增 N、更新 M、跳过 K」。
class ImportOutcome {
  const ImportOutcome({
    required this.courses,
    required this.added,
    required this.updated,
    required this.skipped,
  });

  final List<Course> courses;
  final int added;
  final int updated;
  final int skipped;

  bool get changed => added > 0 || updated > 0;

  @override
  String toString() =>
      'ImportOutcome(added=$added, updated=$updated, skipped=$skipped)';
}

/// 课程身份判定与导入合并策略。
///
/// 背景（审查条目 B7）：原 `importCourses` 是无条件 `add`，
/// 同一个教务系统连点两次导入，课程数就会翻倍。
///
/// 这里用「稳定身份键」去重，而不是直接比整个对象——
/// 后者在教师名多一个空格时就认不出是同一门课。
class CourseImporter {
  const CourseImporter._();

  /// 课程身份键：名称 + 星期 + 节次 + 地点 + 周次规则。
  ///
  /// 刻意**不包含**教师与原始时间文本：这两项在多次导入间可能
  /// 出现空白差异或顺序差异，纳入会导致去重失效。
  /// 周次纳入是因为同一门课可能周一 1-2 节、周三 3-4 节，
  /// 也可能是同一时间不同周次的两个教学班，二者都不应被误合。
  static String identityOf(Course course) {
    final pattern = course.weekPattern;
    final ranges = pattern.ranges
        .map((range) => '${range.start}-${range.end}')
        .join(',');
    return [
      course.name.trim(),
      course.dayOfWeek,
      course.startLesson,
      course.endLesson,
      course.location.trim(),
      ranges,
      pattern.rule.wire,
    ].join('|');
  }

  /// 按合并策略计算导入后的课程列表。
  ///
  /// 传入的 [incoming] 尚未分配 id；[existingNextId] 用于给新课程发号，
  /// 保证新 id 不与已有课程冲突（修复 B3 的另一半）。
  static ImportOutcome apply({
    required List<Course> existing,
    required List<Course> incoming,
    required ImportMode mode,
    required int Function() nextId,
  }) {
    if (mode == ImportMode.replace) {
      final built = <Course>[];
      for (final course in incoming) {
        built.add(course.copyWith(id: nextId()));
      }
      // 同样的入参里若自身有重复，也一并去掉
      final deduped = _dedupe(built);
      return ImportOutcome(
        courses: deduped,
        added: deduped.length,
        updated: 0,
        skipped: incoming.length - deduped.length,
      );
    }

    if (mode == ImportMode.append) {
      final built = <Course>[];
      for (final course in incoming) {
        built.add(course.copyWith(id: nextId()));
      }
      return ImportOutcome(
        courses: [...existing, ...built],
        added: built.length,
        updated: 0,
        skipped: 0,
      );
    }

    // merge：同名同时间同地点同周次的更新，新的追加
    final result = [...existing];
    final indexByIdentity = <String, int>{};
    for (var i = 0; i < result.length; i++) {
      indexByIdentity[identityOf(result[i])] = i;
    }

    var added = 0;
    var updated = 0;
    var skipped = 0;
    for (final course in incoming) {
      final key = identityOf(course);
      final existingIndex = indexByIdentity[key];
      if (existingIndex == null) {
        final created = course.copyWith(id: nextId());
        indexByIdentity[key] = result.length;
        result.add(created);
        added++;
      } else {
        final current = result[existingIndex];
        // 内容完全一致 => 跳过，不计入变更
        if (_sameContent(current, course)) {
          skipped++;
        } else {
          result[existingIndex] = course.copyWith(id: current.id);
          updated++;
        }
      }
    }

    return ImportOutcome(
      courses: result,
      added: added,
      updated: updated,
      skipped: skipped,
    );
  }

  static bool _sameContent(Course a, Course b) =>
      a.teacher == b.teacher && a.rawTime == b.rawTime;

  static List<Course> _dedupe(List<Course> courses) {
    final seen = <String>{};
    final out = <Course>[];
    for (final course in courses) {
      if (seen.add(identityOf(course))) {
        out.add(course);
      }
    }
    return out;
  }
}
