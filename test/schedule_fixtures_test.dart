import 'dart:convert';
import 'dart:io';

import 'package:clark_aams/models/app_settings.dart';
import 'package:clark_aams/models/course.dart';
import 'package:clark_aams/services/schedule_utils.dart';
import 'package:flutter_test/flutter_test.dart';

/// 共享课表算法 fixture 的 Dart 侧验证（P3-2）。
///
/// fixture 位于本仓库的 `shared/schedule-fixtures.json`，
/// Web 仓库有一份**内容相同**的副本（两个仓库互相独立）。
/// 两端各自跑同一套用例——这就是「两端一致」的强制点。
void main() {
  final fixtureFile = File('shared/schedule-fixtures.json');
  late Map<String, dynamic> fixtures;

  setUpAll(() {
    if (!fixtureFile.existsSync()) {
      fail('找不到共享 fixture：${fixtureFile.absolute.path}');
    }
    fixtures = jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;
  });

  group('expand 周次展开', () {
    test('全部用例与 fixture 一致', () {
      final cases = fixtures['expand'] as List;
      expect(cases, isNotEmpty);

      for (final raw in cases) {
        final item = raw as Map<String, dynamic>;
        final name = item['name'] as String;
        final ranges = (item['ranges'] as List)
            .map((r) => WeekRange((r as List)[0] as int, r[1] as int))
            .toList();
        final rule = WeekRule.fromWire(item['rule']);
        final expected = (item['expected'] as List).cast<int>();

        final pattern = WeekPattern(ranges: ranges, rule: rule);
        expect(pattern.expand(), expected, reason: '用例「$name」');
      }
    });
  });

  group('fromWeeks 反推', () {
    test('区间、规则、展开结果均与 fixture 一致', () {
      final cases = fixtures['fromWeeks'] as List;
      expect(cases, isNotEmpty);

      for (final raw in cases) {
        final item = raw as Map<String, dynamic>;
        final name = item['name'] as String;
        final weeks = (item['weeks'] as List).cast<int>();

        final pattern = WeekPattern.fromWeeks(weeks);

        final expectedRanges = (item['expectedRanges'] as List)
            .map((r) => [(r as List)[0] as int, r[1] as int])
            .toList();
        final actualRanges =
            pattern.ranges.map((r) => [r.start, r.end]).toList();
        expect(actualRanges, expectedRanges, reason: '用例「$name」的区间');

        expect(
          pattern.rule.wire,
          item['expectedRule'],
          reason: '用例「$name」的规则',
        );
        expect(
          pattern.expand(),
          (item['expectedExpand'] as List).cast<int>(),
          reason: '用例「$name」的展开',
        );
      }
    });
  });

  group('endTime 结束时间', () {
    test('全部用例与 fixture 一致', () {
      for (final raw in fixtures['endTime'] as List) {
        final item = raw as Map<String, dynamic>;
        expect(
          ScheduleUtils.endTime(
            item['start'] as String,
            item['duration'] as int,
          ),
          item['expected'],
          reason: '用例「${item['name']}」',
        );
      }
    });
  });

  group('isTimeListValid 作息校验', () {
    test('全部用例与 fixture 一致', () {
      for (final raw in fixtures['isTimeListValid'] as List) {
        final item = raw as Map<String, dynamic>;
        expect(
          ScheduleUtils.isTimeListValid((item['times'] as List).cast<String>()),
          item['expected'],
          reason: '用例「${item['name']}」',
        );
      }
    });
  });

  group('currentWeek 当前周', () {
    test('全部用例与 fixture 一致', () {
      for (final raw in fixtures['currentWeek'] as List) {
        final item = raw as Map<String, dynamic>;
        final settings = AppSettingsModel.defaults.copyWith(
          termStartDate: item['termStartDate'] as String,
          maxWeeks: item['maxWeeks'] as int,
        );
        final today = DateTime.parse(item['today'] as String);

        expect(
          ScheduleUtils.currentWeek(settings, today),
          item['expected'],
          reason: '用例「${item['name']}」',
        );
      }
    });
  });
}
