import 'package:flutter/material.dart';

import '../../resources/app_strings.dart';

/// 首页配色。
///
/// 这些颜色原本散落在 `home_page.dart` 顶部的私有常量里。
/// 拆分文件后必须共享，因此提到独立文件；
/// 仍以 `home` 前缀命名，避免与全局主题混淆。
// 全部对齐粉白品牌规范。原来这里有紫蓝（0xff2b2545 作正文、
// 0xff7c6cff 作高亮），既是规范禁止的紫蓝渐变系，也和 Web 端不一致。
const Color homeInk = Color(0xff4a2e3b); // 深梅灰：正文
const Color homeMuted = Color(0xff6b4f5a); // 浅梅灰：次要信息
const Color homeLavender = Color(0xffc93c7d); // 主品牌粉（沿用旧名，避免改十来个调用点）
const Color homePink = Color(0xfff7a8bf); // 品牌柔粉
const Color homeCream = Color(0xfffff9fa); // 粉白底
const Color homePanel = Color(0xffffffff);
const Color homeLine = Color(0xfff7d9e2); // 粉线（原为紫线 0xffe8e3ff）

/// 首页背景渐变用的三个色标。
const List<Color> homeBackgroundGradient = [
  Color(0xfffff9fa),
  Color(0xfffff2f5), // 原为淡紫 0xfff4f1ff，规范禁止紫蓝渐变
  Color(0xfffff7fb),
];

String weekLabel(int week) => AppStrings.homeWeekLabel(week);

String lessonRangeLabel(int startLesson, int endLesson) =>
    AppStrings.homeLessonRangeLabel(startLesson, endLesson);
