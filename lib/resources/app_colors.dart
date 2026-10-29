import 'package:flutter/material.dart';

/// 全站配色。
///
/// 与网页端 `Clark_AAMS_Frontend/src/styles/tokens.css` 是同一套数值：
/// 学生侧「柔和浅色」——浅茜底 + 白卡片 + 带靛蓝色相的柔和阴影；
/// 管理侧「macOS 深灰」——三层灰靠背景深浅分层级，不用渐变与发光。
///
/// 规则：
/// - 正文不用纯黑，最深只到 [ink900]；
/// - 主色只用 indigo，不再出现粉紫以外的第二种强调色；
/// - 任何文字对背景的对比度都不低于 4.5:1。
class AppColors {
  const AppColors._();

  // ---- 品牌 ----
  static const brand700 = Color(0xFF3F38C9);
  static const brand600 = Color(0xFF4F46E5);
  static const brand500 = Color(0xFF6366F1);
  static const brand200 = Color(0xFFC7C6F7);
  static const brand100 = Color(0xFFECEBFE);
  static const brand050 = Color(0xFFF5F4FF);

  // ---- 文字 ----
  static const ink900 = Color(0xFF23252F);
  static const ink700 = Color(0xFF3C3F52);
  static const ink600 = Color(0xFF55596B);
  static const ink500 = Color(0xFF6D7186);
  static const ink400 = Color(0xFF8F93A6);
  static const inkInverse = Color(0xFFFDFDFF);

  // ---- 表面 ----
  static const canvas = Color(0xFFF6F6FB);
  static const canvasDeep = Color(0xFFEFEFF8);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSunken = Color(0xFFF2F2F9);

  // ---- 语义 ----
  static const mint600 = Color(0xFF1E7F63);
  static const mint100 = Color(0xFFE6F5EF);
  static const amber600 = Color(0xFFA4640A);
  static const amber100 = Color(0xFFFDF1DD);
  static const danger600 = Color(0xFFC03A4C);
  static const danger100 = Color(0xFFFBEAEC);
  static const rose500 = Color(0xFFE08AA4);
  static const rose100 = Color(0xFFFDEEF2);

  // ---- 描边 ----
  static const line = Color(0x1423252F);
  static const lineStrong = Color(0x2423252F);

  // ---- 卡片阴影：带靛蓝色相，不是纯灰 ----
  static const shadowSm = [
    BoxShadow(color: Color(0x0D4F46E5), blurRadius: 8, offset: Offset(0, 2)),
  ];
  static const shadowMd = [
    BoxShadow(color: Color(0x144F46E5), blurRadius: 28, offset: Offset(0, 12)),
    BoxShadow(color: Color(0x0A23252F), blurRadius: 6, offset: Offset(0, 2)),
  ];
  static const shadowLg = [
    BoxShadow(color: Color(0x244F46E5), blurRadius: 48, offset: Offset(0, 22)),
    BoxShadow(color: Color(0x0D23252F), blurRadius: 12, offset: Offset(0, 4)),
  ];

  // ---- 管理台（深灰三层）----
  static const admScreen = Color(0xFF161618);
  static const admPanel = Color(0xFF202022);
  static const admCard = Color(0xFF2A2A2C);
  static const admLine = Color(0x1AFFFFFF);
  static const admLineSoft = Color(0x12FFFFFF);
  static const admText = Color(0xF0FFFFFF);
  static const admText2 = Color(0xB8FFFFFF);
  static const admText3 = Color(0x7AFFFFFF);
  static const admAccent = Color(0xFF0A84FF);
  static const admOk = Color(0xFF3DDC97);
  static const admWarn = Color(0xFFF0B429);
  static const admBad = Color(0xFFFF6961);

  /// 课表色块：与网页端 `--course-tone-0..5` 同色。
  /// 都做成很浅的底 + 深色文字，避免大面积高饱和色压住内容。
  static const courseTones = <List<Color>>[
    [Color(0xFFEEECFE), Color(0xFF3F38C9)],
    [Color(0xFFFDEEF2), Color(0xFF9C3B5C)],
    [Color(0xFFE8F4F0), Color(0xFF1E7F63)],
    [Color(0xFFF3EFF8), Color(0xFF5B4380)],
    [Color(0xFFFDF3E6), Color(0xFF9A6010)],
    [Color(0xFFEAF1FB), Color(0xFF2E5B8F)],
  ];

  static List<Color> courseTone(int index) =>
      courseTones[index.abs() % courseTones.length];
}
