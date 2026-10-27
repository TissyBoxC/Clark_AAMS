import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 拦住粉白品牌色规范。
///
/// 背景：App 里曾散落着紫蓝色（`0xff2b2545` 作正文、`0xff7c6cff` 作高亮、
/// `0xffe8e3ff` 作边框、`0xfff4f1ff` 作渐变中段），既违反「不要紫蓝渐变」
/// 的规范，也和 Web 端不一致。这类问题靠人工翻代码很难发现——
/// 常量分散在十几个文件里。
///
/// 所以这里直接扫源码：任何「蓝紫明显多于红」的颜色都会被抓出来。
///
/// 两个例外：
/// - 注释行跳过（注释里可能提到历史色值，那不是实际使用的颜色）。
/// - `services/schedule_utils.dart` 是课程配色，20 种颜色用来区分不同课程，
///   属于功能色而非品牌色，不受品牌规范约束（Web 端同样保留）。
void main() {
  /// 课程配色文件：用颜色区分不同课程，不是品牌色。
  const functionalColorFiles = {r'services\schedule_utils.dart'};

  /// 规范明确允许的点缀色。判定逻辑是「蓝多于红」，而点缀蓝本来就蓝，
  /// 所以必须单独放行，否则会把合规用法误判成违规。
  const allowedAccents = {'66ccff'};

  group('粉白品牌色规范', () {
    test('源码里不出现紫蓝色', () {
      final offenders = <String>[];

      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (functionalColorFiles.any(entity.path.endsWith)) continue;

        var lines = entity.readAsLinesSync();
        for (var index = 0; index < lines.length; index++) {
          final line = lines[index];
          // 跳过整行注释
          if (line.trimLeft().startsWith('//')) continue;

          for (final match in RegExp(r'0x[fF]{2}([0-9a-fA-F]{6})').allMatches(line)) {
            final hex = match.group(1)!.toLowerCase();
            if (allowedAccents.contains(hex)) continue;

            final r = int.parse(hex.substring(0, 2), radix: 16);
            final g = int.parse(hex.substring(2, 4), radix: 16);
            final b = int.parse(hex.substring(4, 6), radix: 16);

            // 紫蓝的特征：蓝色分量明显高于红色，且整体不是中性灰
            // （中性灰三个分量接近，不受影响）。
            if (b > r + 24 && b > g + 24) {
              offenders.add('${entity.path}:${index + 1} 0xff$hex');
            }
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: '发现紫蓝色，粉白规范不允许：\n${offenders.join('\n')}',
      );
    });

    test('主色调仍是品牌粉', () {
      final theme = File('lib/main.dart').readAsStringSync();
      expect(theme.toLowerCase(), contains('0xffc93c7d'));
    });

    test('正文色仍是深梅灰', () {
      final source = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .map((file) => file.readAsStringSync())
          .join('\n');
      expect(source.toLowerCase(), contains('0xff4a2e3b'));
    });
  });
}
