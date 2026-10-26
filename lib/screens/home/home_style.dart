import 'package:flutter/material.dart';

import '../../resources/app_strings.dart';

/// 首页配色。
///
/// 这些颜色原本散落在 `home_page.dart` 顶部的私有常量里。
/// 拆分文件后必须共享，因此提到独立文件；
/// 仍以 `home` 前缀命名，避免与全局主题混淆。
const Color homeInk = Color(0xff2b2545);
const Color homeMuted = Color(0xff6b4f5a);
const Color homeLavender = Color(0xff7c6cff);
const Color homePink = Color(0xffff7eb6);
const Color homeCream = Color(0xfffff9fa);
const Color homePanel = Color(0xffffffff);
const Color homeLine = Color(0xffe8e3ff);

/// 首页背景渐变用的三个色标。
const List<Color> homeBackgroundGradient = [
  Color(0xfffff9fa),
  Color(0xfff4f1ff),
  Color(0xfffff7fb),
];

String weekLabel(int week) => AppStrings.homeWeekLabel(week);

String lessonRangeLabel(int startLesson, int endLesson) =>
    AppStrings.homeLessonRangeLabel(startLesson, endLesson);
