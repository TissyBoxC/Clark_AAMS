import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 共享契约 fixture 的完整性检查（P2-1）。
///
/// `shared/schedule-fixtures.json` 是 App 与 Web 共用的课表解析基准。
/// 两个仓库无法跨仓库 import，所以它被复制成了多份：
///
///     shared/schedule-fixtures.json                       顶层（权威）
///     Clark_AAMS/shared/schedule-fixtures.json            App 读取（本仓库）
///     Clark_AAMS_Frontend/shared/schedule-fixtures.json   Web 读取
///
/// 危险之处不在于「某一份改了」，而在于**只改了其中一份**：
/// App 与 Web 会各自拿着一份不同的基准跑绿，线上却对不上。
/// 两边都绿比一边红更难排查。
///
/// 跨仓库比对只能在本地做（CI 只 checkout 单个仓库），
/// 所以这里钉住本仓库副本的摘要：它一旦变化，这个用例就红，
/// 提醒你去同步另外两份，并跑一遍：
///
///     python tools/check-shared-fixtures.py
///
/// 更新基准的正确姿势：先确认顶层 shared/ 是对的，再
///     python tools/check-shared-fixtures.py --fix
/// 然后把下面 expectedSha256Prefix 改成新值（Web 侧同步改）。
void main() {
  /// 三份副本一致时的 sha256 前缀（与 Web 侧 `shared-fixture.test.ts` 一致）。
  const expectedSha256Prefix = 'a811360930cbd5c1';

  final fixtureFile = File('shared/schedule-fixtures.json');

  test('契约 fixture 未被单方面修改', () {
    expect(fixtureFile.existsSync(), isTrue,
        reason: '找不到 shared/schedule-fixtures.json');

    final digest = _sha256Hex(fixtureFile.readAsBytesSync());
    expect(
      digest.substring(0, expectedSha256Prefix.length),
      expectedSha256Prefix,
      reason: 'shared/schedule-fixtures.json 已改变。\n'
          '  App 与 Web 共用这份基准，只改一份会让两边各跑各的。\n'
          '  请确认顶层 shared/ 是想要的版本后运行：\n'
          '      python tools/check-shared-fixtures.py --fix\n'
          '  再把本文件与 Web 侧对应的摘要一起更新为新值。\n'
          '  当前值：${digest.substring(0, 16)}',
    );
  });

  test('契约 fixture 是可解析的 JSON 且含实际内容', () {
    final data = jsonDecode(fixtureFile.readAsStringSync());
    expect(data, isA<Map<String, dynamic>>());
    expect((data as Map<String, dynamic>).isNotEmpty, isTrue,
        reason: 'fixture 不应为空，否则「一致」没有意义');
  });

  test('摘要算法本身正确（对照已知向量）', () {
    // 空串与 "abc" 的 sha256 是公开已知值，用来确认实现没写错
    expect(_sha256Hex(const []),
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855');
    expect(_sha256Hex(utf8.encode('abc')),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad');
  });
}

/// SHA-256 的纯 Dart 实现。
///
/// 不引入 `crypto` 包：仅为一条测试加依赖不值得；也不调用
/// `certutil`/`sha256sum`——那会让测试依赖平台与外部命令。
const List<int> _k = [
  0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1,
  0x923f82a4, 0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
  0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786,
  0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
  0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147,
  0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
  0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b,
  0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
  0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a,
  0x5b9cca4f, 0x682e6ff3, 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
  0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
];

const int _mask32 = 0xffffffff;

int _rotr(int x, int n) => ((x >> n) | (x << (32 - n))) & _mask32;

String _sha256Hex(List<int> message) {
  final h = <int>[
    0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
    0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
  ];

  // 填充：0x80，补零到 len % 64 == 56，再接 64 位大端长度
  final bitLength = message.length * 8;
  final padded = <int>[...message, 0x80];
  while (padded.length % 64 != 56) {
    padded.add(0);
  }
  for (var i = 7; i >= 0; i--) {
    padded.add((bitLength >> (i * 8)) & 0xff);
  }

  for (var chunk = 0; chunk < padded.length; chunk += 64) {
    final w = List<int>.filled(64, 0);
    for (var i = 0; i < 16; i++) {
      final j = chunk + i * 4;
      w[i] = (padded[j] << 24) |
          (padded[j + 1] << 16) |
          (padded[j + 2] << 8) |
          padded[j + 3];
    }
    for (var i = 16; i < 64; i++) {
      final s0 = _rotr(w[i - 15], 7) ^ _rotr(w[i - 15], 18) ^ (w[i - 15] >> 3);
      final s1 = _rotr(w[i - 2], 17) ^ _rotr(w[i - 2], 19) ^ (w[i - 2] >> 10);
      w[i] = (w[i - 16] + s0 + w[i - 7] + s1) & _mask32;
    }

    var a = h[0], b = h[1], c = h[2], d = h[3];
    var e = h[4], f = h[5], g = h[6], hh = h[7];

    for (var i = 0; i < 64; i++) {
      final s1 = _rotr(e, 6) ^ _rotr(e, 11) ^ _rotr(e, 25);
      final ch = (e & f) ^ ((~e & _mask32) & g);
      final temp1 = (hh + s1 + ch + _k[i] + w[i]) & _mask32;
      final s0 = _rotr(a, 2) ^ _rotr(a, 13) ^ _rotr(a, 22);
      final maj = (a & b) ^ (a & c) ^ (b & c);
      final temp2 = (s0 + maj) & _mask32;

      hh = g;
      g = f;
      f = e;
      e = (d + temp1) & _mask32;
      d = c;
      c = b;
      b = a;
      a = (temp1 + temp2) & _mask32;
    }

    h[0] = (h[0] + a) & _mask32;
    h[1] = (h[1] + b) & _mask32;
    h[2] = (h[2] + c) & _mask32;
    h[3] = (h[3] + d) & _mask32;
    h[4] = (h[4] + e) & _mask32;
    h[5] = (h[5] + f) & _mask32;
    h[6] = (h[6] + g) & _mask32;
    h[7] = (h[7] + hh) & _mask32;
  }

  return h.map((v) => v.toRadixString(16).padLeft(8, '0')).join();
}
