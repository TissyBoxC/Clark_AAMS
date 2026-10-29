import 'package:flutter/material.dart';

/// 字号、间距、圆角、动效节奏。
///
/// 数值与网页端 `tokens.css` 一一对应，改一边另一边也要跟着改，
/// 否则三端（web / App / 桌面）会出现「同样叫大标题却不一样大」的情况。
class AppMetrics {
  const AppMetrics._();

  // 字号阶梯（逻辑像素）
  static const double hero = 40;
  static const double h1 = 28;
  static const double h2 = 22;
  static const double h3 = 18;
  static const double body = 15;
  static const double small = 13;
  static const double tiny = 12;

  // 间距（4 的倍数）
  static const double sp1 = 4;
  static const double sp2 = 8;
  static const double sp3 = 12;
  static const double sp4 = 16;
  static const double sp5 = 24;
  static const double sp6 = 32;
  static const double sp7 = 48;

  // 圆角：控件 14、卡片 22、大表面 28
  static const double rSm = 12;
  static const double rMd = 14;
  static const double rLg = 18;
  static const double rXl = 22;
  static const double r2xl = 28;
  static const double rPill = 999;

  // 动效：统一节奏
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration base = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 420);
  static const Curve ease = Cubic(0.22, 1, 0.36, 1);

  /// 页面左右留白：手机 18，宽屏 32。
  static double pagePadding(double width) => width >= 900 ? 32 : 18;

  /// 内容最大宽度。桌面端不让文字拉到整屏宽。
  static const double content = 1180;
  static const double contentReading = 720;

  static EdgeInsets pageInsets(double width) =>
      EdgeInsets.symmetric(horizontal: pagePadding(width));
}
