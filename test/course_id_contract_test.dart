import 'package:clark_aams/models/course.dart';
import 'package:flutter_test/flutter_test.dart';

/// 课程 id 的解析契约（P3-3）。
///
/// 背景：后端 `POST /courses/schedule` 此前**不回传 id**，
/// 而 `PUT/DELETE /courses/schedule/{id}` 都要用。
/// 客户端于是只能按「数组下标 + 1」猜，列表顺序一变就会改错、删错课。
///
/// 后端已修（`CourseDto` 增加 id），App 侧在这里钉住两件事：
///
/// 1. 服务端给了 id 就用它——不能因为调用方传了 fallbackId 就被覆盖
/// 2. 服务端没给 id（老后端）时才退回 fallbackId
///
/// 第 1 条尤其容易被写反。`fromJson(json, fallbackId: i + 1)` 这种调用
/// 看起来像「以 fallback 为准」，实际必须是「以服务端为准」。
void main() {
  Map<String, Object?> serverCourse({int? id}) => <String, Object?>{
    ?'id': id,
    'name': '高等数学',
    'dayOfWeek': 1,
    'startLesson': 1,
    'endLesson': 2,
    'location': 'A101',
    'teacher': '张老师',
    'weeks': [1, 2, 3],
    'weekRanges': [
      [1, 16],
    ],
    'weekRule': 'ALL',
  };

  test('服务端返回的 id 被直接采用', () {
    final course = Course.fromJson(serverCourse(id: 42), fallbackId: 1);
    expect(course.id, 42);
  });

  test('服务端 id 优先于 fallbackId，不会被覆盖', () {
    // 这是最容易被写反的一条：调用方习惯性传 fallbackId: i + 1，
    // 如果实现里让 fallback 抢先，就会把真实主键冲掉。
    final course = Course.fromJson(serverCourse(id: 7), fallbackId: 99);
    expect(course.id, 7);
  });

  test('老后端不回传 id 时退回 fallbackId', () {
    final course = Course.fromJson(serverCourse(), fallbackId: 3);
    expect(course.id, 3);
  });

  test('既无 id 也无 fallbackId 时为 0（表示尚未落库）', () {
    final course = Course.fromJson(serverCourse());
    expect(course.id, 0);
  });

  test('多门课各自的 id 不会被互相顶掉', () {
    final courses = [
      Course.fromJson(serverCourse(id: 5), fallbackId: 1),
      Course.fromJson(serverCourse(id: 9), fallbackId: 2),
      Course.fromJson(serverCourse(id: 12), fallbackId: 3),
    ];
    expect(courses.map((c) => c.id).toList(), [5, 9, 12]);
  });
}
