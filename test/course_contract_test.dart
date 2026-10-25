import 'package:clark_aams/models/course.dart';
import 'package:flutter_test/flutter_test.dart';

/// 服务端课表契约（P3-1）。
///
/// 服务端返回 camelCase 字段 + weekRanges/weekRule 真相源，
/// App 必须能直接解析，且回传时只提交真相源字段。
void main() {
  group('服务端课表解析', () {
    test('解析 weekRanges + weekRule（服务端形态）', () {
      final course = Course.fromJson({
        'name': '高等数学',
        'dayOfWeek': 1,
        'startLesson': 1,
        'endLesson': 2,
        'location': 'A101',
        'teacher': '张老师',
        'rawTime': '',
        'weeks': [1, 2, 3, 4],
        'weekRanges': [
          [1, 4],
        ],
        'weekRule': 'ALL',
        'startWeek': 1,
        'endWeek': 4,
      }, fallbackId: 7);

      expect(course.id, 7);
      expect(course.name, '高等数学');
      expect(course.dayOfWeek, 1);
      expect(course.startLesson, 1);
      expect(course.endLesson, 2);
      expect(course.weekPattern.rule, WeekRule.all);
      expect(course.activeWeeks, [1, 2, 3, 4]);
    });

    test('单周课程展开为奇数周', () {
      final course = Course.fromJson({
        'name': '单周实验',
        'dayOfWeek': 3,
        'startLesson': 5,
        'endLesson': 6,
        'weekRanges': [
          [1, 9],
        ],
        'weekRule': 'ODD',
      });

      expect(course.weekPattern.rule, WeekRule.odd);
      expect(course.activeWeeks, [1, 3, 5, 7, 9]);
    });

    test('双周课程展开为偶数周', () {
      final course = Course.fromJson({
        'name': '双周实验',
        'dayOfWeek': 3,
        'startLesson': 5,
        'endLesson': 6,
        'weekRanges': [
          [2, 10],
        ],
        'weekRule': 'EVEN',
      });

      expect(course.weekPattern.rule, WeekRule.even);
      expect(course.activeWeeks, [2, 4, 6, 8, 10]);
    });

    test('缺省 weekRule 视为全周', () {
      final course = Course.fromJson({
        'name': '无标记课',
        'weekRanges': [
          [1, 3],
        ],
      });

      expect(course.weekPattern.rule, WeekRule.all);
      expect(course.activeWeeks, [1, 2, 3]);
    });

    test('weekRule 大小写容错', () {
      final lower = Course.fromJson({
        'name': '小写规则',
        'weekRanges': [
          [1, 5],
        ],
        'weekRule': 'odd',
      });

      expect(lower.weekPattern.rule, WeekRule.odd);
    });
  });

  group('写请求字段', () {
    test('WeekRule.wire 输出大写线格式', () {
      expect(WeekRule.all.wire, 'ALL');
      expect(WeekRule.odd.wire, 'ODD');
      expect(WeekRule.even.wire, 'EVEN');
    });

    test('WeekRange 能还原为二元组', () {
      final pattern = WeekPattern.fromWeeks([1, 2, 3, 4, 5, 6]);

      expect(pattern.ranges.length, 1);
      expect(pattern.ranges.first.start, 1);
      expect(pattern.ranges.first.end, 6);
    });
  });
}
