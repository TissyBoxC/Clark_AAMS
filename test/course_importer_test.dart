import 'package:clark_aams/models/course.dart';
import 'package:clark_aams/services/course_importer.dart';
import 'package:flutter_test/flutter_test.dart';

/// 导入去重与 id 分配测试（审查条目 B7 / B3）。
void main() {
  Course course({
    String name = '高等数学',
    int day = 1,
    int start = 1,
    int end = 2,
    String location = 'A101',
    String teacher = '张三',
    WeekPattern? pattern,
  }) {
    return Course(
      id: 0,
      name: name,
      startWeek: 1,
      endWeek: 16,
      dayOfWeek: day,
      startLesson: start,
      endLesson: end,
      location: location,
      teacher: teacher,
      weekPattern: pattern ?? WeekPattern.fromWeeks(List.generate(16, (i) => i + 1)),
    );
  }

  group('身份键', () {
    test('教师名或原始时间文本不同，仍视为同一门课', () {
      final a = course(teacher: '张三');
      final b = course(teacher: '张三 ');
      expect(CourseImporter.identityOf(a), CourseImporter.identityOf(b));
    });

    test('地点不同视为不同课', () {
      expect(
        CourseImporter.identityOf(course(location: 'A101')),
        isNot(CourseImporter.identityOf(course(location: 'B202'))),
      );
    });

    test('周次规则不同视为不同课', () {
      final odd = course(
        pattern: const WeekPattern(ranges: [WeekRange(1, 16)], rule: WeekRule.odd),
      );
      expect(
        CourseImporter.identityOf(course()),
        isNot(CourseImporter.identityOf(odd)),
      );
    });
  });

  group('merge 模式', () {
    test('连续导入两次，课程数不变（B7 回归）', () {
      var counter = 0;
      int nextId() => ++counter;

      final incoming = [course(), course(name: '大学英语', day: 2, start: 3, end: 4)];

      final first = CourseImporter.apply(
        existing: const [],
        incoming: incoming,
        mode: ImportMode.merge,
        nextId: nextId,
      );
      expect(first.courses.length, 2);
      expect(first.added, 2);
      expect(first.skipped, 0);

      final second = CourseImporter.apply(
        existing: first.courses,
        incoming: incoming,
        mode: ImportMode.merge,
        nextId: nextId,
      );
      expect(second.courses.length, 2, reason: '第二次导入不应新增课程');
      expect(second.added, 0);
      expect(second.skipped, 2);
      expect(second.changed, isFalse);
    });

    test('内容变化时更新而非新增', () {
      var counter = 0;
      int nextId() => ++counter;

      final first = CourseImporter.apply(
        existing: const [],
        incoming: [course(teacher: '张三')],
        mode: ImportMode.merge,
        nextId: nextId,
      );
      final originalId = first.courses.single.id;

      final second = CourseImporter.apply(
        existing: first.courses,
        incoming: [course(teacher: '李四')],
        mode: ImportMode.merge,
        nextId: nextId,
      );
      expect(second.courses.length, 1);
      expect(second.updated, 1);
      expect(second.courses.single.id, originalId, reason: '更新应保留原 id');
      expect(second.courses.single.teacher, '李四');
    });

    test('新增课程拿到不冲突的 id', () {
      var counter = 0;
      int nextId() => ++counter;

      final first = CourseImporter.apply(
        existing: const [],
        incoming: [course()],
        mode: ImportMode.merge,
        nextId: nextId,
      );
      final second = CourseImporter.apply(
        existing: first.courses,
        incoming: [course(name: '体育', day: 5, start: 5, end: 6)],
        mode: ImportMode.merge,
        nextId: nextId,
      );
      final ids = second.courses.map((c) => c.id).toList();
      expect(ids.toSet().length, ids.length, reason: 'id 不应重复');
    });

    test('已有课程不被删除', () {
      final existing = [
        Course(
          id: 99,
          name: '手工添加的课',
          startWeek: 1,
          endWeek: 8,
          dayOfWeek: 3,
          startLesson: 5,
          endLesson: 6,
          location: 'Z999',
          weekPattern: WeekPattern.fromWeeks([1, 2, 3, 4, 5, 6, 7, 8]),
        ),
      ];
      var counter = 100;
      int nextId() => ++counter;

      final outcome = CourseImporter.apply(
        existing: existing,
        incoming: [course()],
        mode: ImportMode.merge,
        nextId: nextId,
      );
      expect(outcome.courses.length, 2);
      expect(outcome.courses.any((c) => c.id == 99), isTrue);
    });
  });

  group('replace 模式', () {
    test('整体替换现有课表', () {
      var counter = 0;
      int nextId() => ++counter;

      final existing = [course(name: '旧课')];
      final outcome = CourseImporter.apply(
        existing: existing,
        incoming: [course(name: '新课')],
        mode: ImportMode.replace,
        nextId: nextId,
      );
      expect(outcome.courses.length, 1);
      expect(outcome.courses.single.name, '新课');
    });

    test('入参自身重复时去重', () {
      var counter = 0;
      int nextId() => ++counter;

      final outcome = CourseImporter.apply(
        existing: const [],
        incoming: [course(), course()],
        mode: ImportMode.replace,
        nextId: nextId,
      );
      expect(outcome.courses.length, 1);
      expect(outcome.skipped, 1);
    });
  });

  group('append 模式', () {
    test('无条件追加，允许重复', () {
      var counter = 0;
      int nextId() => ++counter;

      final existing = [course()];
      final outcome = CourseImporter.apply(
        existing: existing,
        incoming: [course()],
        mode: ImportMode.append,
        nextId: nextId,
      );
      expect(outcome.courses.length, 2);
      expect(outcome.added, 1);
    });
  });

  group('id 分配稳定性（B3 回归）', () {
    test('连续新增 100 次，id 始终唯一且严格递增', () {
      var counter = 0;
      int nextId() => ++counter;

      var existing = <Course>[];
      final seen = <int>{};
      for (var i = 0; i < 100; i++) {
        final outcome = CourseImporter.apply(
          existing: existing,
          incoming: [course(name: '课程$i', start: 1 + (i % 10))],
          mode: ImportMode.merge,
          nextId: nextId,
        );
        existing = outcome.courses;
        for (final c in outcome.courses) {
          seen.add(c.id);
        }
      }
      expect(existing.length, 100);
      expect(seen.length, 100, reason: '100 次新增不应出现重复 id');
      final ids = existing.map((c) => c.id).toList();
      expect(ids.toSet().length, ids.length);
    });
  });
}
