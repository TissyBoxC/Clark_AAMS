import 'package:clark_aams/models/course.dart';
import 'package:flutter_test/flutter_test.dart';

/// 周次模型回归测试。
///
/// 锁死 P0-1 的核心约定：`weekPattern` 是唯一真相源，
/// 不会再出现「1-3,5-16 被算成 1..16」「1-16(单) 把偶数周算进来」。
void main() {
  group('WeekPattern.fromWeeks', () {
    test('不连续段保持独立，不合成为一个大区间', () {
      final pattern = WeekPattern.fromWeeks([
        1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, //
      ]);
      expect(pattern.ranges.length, 2);
      expect(pattern.ranges.first.start, 1);
      expect(pattern.ranges.first.end, 3);
      expect(pattern.ranges.last.start, 5);
      expect(pattern.ranges.last.end, 16);
      expect(pattern.rule, WeekRule.all);
    });

    test('全奇数识别为单周', () {
      final pattern = WeekPattern.fromWeeks([1, 3, 5, 7]);
      expect(pattern.rule, WeekRule.odd);
      expect(pattern.expand(), [1, 3, 5, 7]);
    });

    test('全偶数识别为双周', () {
      final pattern = WeekPattern.fromWeeks([2, 4, 6, 8]);
      expect(pattern.rule, WeekRule.even);
      expect(pattern.expand(), [2, 4, 6, 8]);
    });

    test('空列表返回空规则', () {
      final pattern = WeekPattern.fromWeeks(const []);
      expect(pattern.isEmpty, isTrue);
      expect(pattern.firstWeek, isNull);
      expect(pattern.lastWeek, isNull);
    });

    test('越界周次被丢弃', () {
      final pattern = WeekPattern.fromWeeks([0, 1, 2, 31, 40]);
      expect(pattern.expand(), [1, 2]);
    });
  });

  group('WeekPattern 展开', () {
    test('单周区间不会混入偶数周', () {
      const pattern = WeekPattern(
        ranges: [WeekRange(1, 16)],
        rule: WeekRule.odd,
      );
      expect(pattern.expand(), [1, 3, 5, 7, 9, 11, 13, 15]);
      expect(pattern.firstWeek, 1);
      expect(pattern.lastWeek, 15);
    });

    test('双周区间不会混入奇数周', () {
      const pattern = WeekPattern(
        ranges: [WeekRange(1, 8)],
        rule: WeekRule.even,
      );
      expect(pattern.expand(), [2, 4, 6, 8]);
    });

    test('多区间 + 单周', () {
      const pattern = WeekPattern(
        ranges: [WeekRange(1, 4), WeekRange(10, 12)],
        rule: WeekRule.odd,
      );
      expect(pattern.expand(), [1, 3, 11]);
    });
  });

  group('Course 周次判定', () {
    Course buildCourse(WeekPattern pattern, {int start = 1, int end = 16}) {
      return Course(
        id: 1,
        name: '高等数学',
        startWeek: start,
        endWeek: end,
        dayOfWeek: 1,
        startLesson: 1,
        endLesson: 2,
        location: 'A101',
        weekPattern: pattern,
      );
    }

    test('断档周不上课（C1 回归）', () {
      final course = buildCourse(
        WeekPattern.fromWeeks([1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]),
      );
      expect(course.matchesWeek(4), isFalse, reason: '第4周不应上课');
      expect(course.matchesWeek(3), isTrue);
      expect(course.matchesWeek(5), isTrue);
    });

    test('单周课程偶数周不上课（C3 回归）', () {
      final course = buildCourse(
        const WeekPattern(ranges: [WeekRange(1, 16)], rule: WeekRule.odd),
      );
      expect(course.matchesWeek(2), isFalse, reason: '第2周是双周');
      expect(course.matchesWeek(3), isTrue);
    });

    test('weekText 保留多段与单双周', () {
      final course = buildCourse(
        WeekPattern.fromWeeks([1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]),
      );
      expect(course.weekText, '1-3,5-16周');
    });

    test('without pattern 时回退到 startWeek..endWeek', () {
      final course = buildCourse(WeekPattern.empty, start: 2, end: 6);
      expect(course.matchesWeek(1), isFalse);
      expect(course.matchesWeek(4), isTrue);
      expect(course.matchesWeek(7), isFalse);
    });
  });

  group('JSON 往返', () {
    test('写出 weekRanges / weekRule，读回一致', () {
      final course = Course(
        id: 7,
        name: '数据结构',
        startWeek: 1,
        endWeek: 15,
        dayOfWeek: 2,
        startLesson: 3,
        endLesson: 4,
        location: 'B202',
        weekPattern: const WeekPattern(
          ranges: [WeekRange(1, 16)],
          rule: WeekRule.odd,
        ),
      );

      final json = course.toJson();
      expect(json['weeks'], [1, 3, 5, 7, 9, 11, 13, 15]);
      expect(json['weekRule'], 'ODD');

      final restored = Course.fromJson(json);
      expect(restored.weekPattern.rule, WeekRule.odd);
      expect(restored.weekPattern.ranges.length, 1);
      expect(restored.activeWeeks, [1, 3, 5, 7, 9, 11, 13, 15]);
      expect(restored.startWeek, 1);
      expect(restored.endWeek, 15, reason: '末周应派生自真实上课周');
    });

    test('只有旧 weeks 字段的 JSON 能反推区间', () {
      final restored = Course.fromJson(<String, Object?>{
        'id': 3,
        'name': '旧课程',
        'startWeek': 1,
        'endWeek': 16,
        'dayOfWeek': 1,
        'startLesson': 1,
        'endLesson': 2,
        'location': 'C303',
        'weeks': [1, 2, 3, 5, 6],
      });
      expect(restored.weekPattern.ranges.length, 2);
      expect(restored.matchesWeek(4), isFalse);
    });

    test('后端 weekRanges 为数组数组时正确解析', () {
      final restored = Course.fromJson(<String, Object?>{
        'id': 4,
        'name': '后端课程',
        'dayOfWeek': 3,
        'startLesson': 5,
        'endLesson': 6,
        'location': 'D404',
        'weekRanges': [
          [1, 8],
        ],
        'weekRule': 'EVEN',
      });
      expect(restored.activeWeeks, [2, 4, 6, 8]);
      expect(restored.matchesWeek(3), isFalse);
      expect(restored.matchesWeek(4), isTrue);
    });
  });
}
