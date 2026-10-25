import 'dart:convert';

import 'package:clark_aams/utils/json_util.dart';
import 'package:flutter_test/flutter_test.dart';

/// JSON 解析助手（P4-2）。
///
/// 这个工具是为了收敛代码库里 19 处重复的
/// 「`is Map<String, Object?>` / `is Map` 二选一」写法。
/// 关键风险是**漏掉分支导致数据被静默丢弃**，所以重点测这里。
void main() {
  group('asMap', () {
    test('直接接受 Map<String, Object?>', () {
      final value = JsonUtil.asMap(<String, Object?>{'a': 1});
      expect(value, {'a': 1});
    });

    test('接受 Map<String, dynamic>（jsonDecode 的真实产物）', () {
      final decoded = jsonDecode('{"name":"高等数学","dayOfWeek":1}');
      expect(decoded, isA<Map<String, dynamic>>());

      final value = JsonUtil.asMap(decoded);
      expect(value, isNotNull);
      expect(value!['name'], '高等数学');
      expect(value['dayOfWeek'], 1);
    });

    test('接受 Map<dynamic, dynamic>', () {
      final value = JsonUtil.asMap(<dynamic, dynamic>{'k': 'v'});
      expect(value, {'k': 'v'});
    });

    test('非 Map 返回 null', () {
      expect(JsonUtil.asMap(null), isNull);
      expect(JsonUtil.asMap('text'), isNull);
      expect(JsonUtil.asMap(42), isNull);
      expect(JsonUtil.asMap(<Object?>[]), isNull);
    });
  });

  group('asMapList', () {
    test('转换数组里的每个对象', () {
      final decoded = jsonDecode('[{"n":1},{"n":2}]');
      final list = JsonUtil.asMapList(decoded);

      expect(list.length, 2);
      expect(list[0]['n'], 1);
      expect(list[1]['n'], 2);
    });

    test('跳过非对象元素而不是整体失败', () {
      final list = JsonUtil.asMapList(<Object?>[
        <String, Object?>{'n': 1},
        'not a map',
        null,
        42,
        <String, Object?>{'n': 2},
      ]);

      expect(list.length, 2, reason: '非对象元素应被跳过');
      expect(list[0]['n'], 1);
      expect(list[1]['n'], 2);
    });

    test('非数组返回空列表', () {
      expect(JsonUtil.asMapList(null), isEmpty);
      expect(JsonUtil.asMapList('x'), isEmpty);
      expect(JsonUtil.asMapList(<String, Object?>{}), isEmpty);
    });
  });

  group('tryDecode', () {
    test('正常 JSON 解码', () {
      expect(JsonUtil.tryDecode('{"a":1}'), {'a': 1});
    });

    test('非法 JSON 返回 null 而不抛异常', () {
      expect(JsonUtil.tryDecode('{broken'), isNull);
      expect(JsonUtil.tryDecode(''), isNull);
      expect(JsonUtil.tryDecode('   '), isNull);
      expect(JsonUtil.tryDecode(null), isNull);
    });
  });

  group('标量转换', () {
    test('asInt 兼容 int/double/字符串', () {
      expect(JsonUtil.asInt(3), 3);
      expect(JsonUtil.asInt(3.7), 3);
      expect(JsonUtil.asInt('12'), 12);
      expect(JsonUtil.asInt(' 12 '), 12);
      expect(JsonUtil.asInt('abc'), isNull);
      expect(JsonUtil.asInt(null), isNull);
    });

    test('asString 把 null 转空串并去空白', () {
      expect(JsonUtil.asString('  hi  '), 'hi');
      expect(JsonUtil.asString(null), '');
      expect(JsonUtil.asString(7), '7');
    });

    test('asBool 兼容 true/1/"true"', () {
      expect(JsonUtil.asBool(true), isTrue);
      expect(JsonUtil.asBool(1), isTrue);
      expect(JsonUtil.asBool('true'), isTrue);
      expect(JsonUtil.asBool('TRUE'), isTrue);
      expect(JsonUtil.asBool(false), isFalse);
      expect(JsonUtil.asBool(0), isFalse);
      expect(JsonUtil.asBool('false'), isFalse);
      expect(JsonUtil.asBool(null), isFalse);
      expect(JsonUtil.asBool('???', fallback: true), isTrue);
    });
  });

  group('端到端：服务端课程 JSON', () {
    test('解析课表数组时不丢数据', () {
      const raw = '''
      [
        {"name":"高等数学","dayOfWeek":1,"startLesson":1,"endLesson":2,
         "weekRanges":[[1,16]],"weekRule":"ALL"},
        {"name":"单周实验","dayOfWeek":3,"startLesson":5,"endLesson":6,
         "weekRanges":[[1,9]],"weekRule":"ODD"}
      ]
      ''';

      final courses = JsonUtil.asMapList(JsonUtil.tryDecode(raw));

      expect(courses.length, 2);
      expect(courses[0]['name'], '高等数学');
      expect(courses[1]['weekRule'], 'ODD');
    });

    test('嵌套的 weekRanges 保持结构', () {
      final course = JsonUtil.asMap(JsonUtil.tryDecode(
        '{"weekRanges":[[1,8],[10,16]]}',
      ))!;
      final ranges = JsonUtil.asList(course['weekRanges'])!;

      expect(ranges.length, 2);
      expect(JsonUtil.asList(ranges[0]), [1, 8]);
      expect(JsonUtil.asList(ranges[1]), [10, 16]);
    });
  });
}
