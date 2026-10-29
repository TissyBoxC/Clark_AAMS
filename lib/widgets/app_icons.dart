import 'package:flutter/material.dart';

/// 应用图标集。
///
/// 只用 Material 自带图标，并按"用户认得出的含义"挑选：
/// 首页、课表、导入、题目、设置、账号各一枚，其余装饰性位置不放图标。
/// 这样既不增加字体体积，也避免图标风格混杂。
class AppIcons {
  const AppIcons._();

  static const home = Icons.space_dashboard_outlined;
  static const homeActive = Icons.space_dashboard;
  static const schedule = Icons.calendar_month_outlined;
  static const scheduleActive = Icons.calendar_month;
  static const import = Icons.file_download_outlined;
  static const importActive = Icons.file_download;
  static const practice = Icons.auto_stories_outlined;
  static const practiceActive = Icons.auto_stories;
  static const mine = Icons.person_outline;
  static const mineActive = Icons.person;

  static const camera = Icons.image_outlined;
  static const ticket = Icons.confirmation_number_outlined;
  static const school = Icons.account_balance_outlined;
  static const settings = Icons.settings_outlined;
  static const account = Icons.badge_outlined;
  static const about = Icons.info_outline;
  static const widget = Icons.widgets_outlined;

  static const arrowRight = Icons.arrow_forward;
  static const arrowLeft = Icons.arrow_back;
  static const chevronRight = Icons.chevron_right;
  static const chevronDown = Icons.expand_more;
  static const close = Icons.close;
  static const check = Icons.check;
  static const plus = Icons.add;
  static const edit = Icons.edit_outlined;
  static const delete = Icons.delete_outline;
  static const copy = Icons.copy_rounded;
  static const refresh = Icons.refresh;
  static const logout = Icons.logout;
  static const alert = Icons.error_outline;
  static const clock = Icons.schedule;
  static const location = Icons.place_outlined;
  static const person = Icons.person_outline;
  static const search = Icons.search;
  static const download = Icons.download_outlined;
  static const mail = Icons.mail_outline;
  static const shield = Icons.verified_user_outlined;
  static const chart = Icons.bar_chart;
  static const server = Icons.dns_outlined;

  /// 课表里的星期缩写，与 [AppStrings.weekLabels] 一一对应。
  static const weekdayShort = ['一', '二', '三', '四', '五', '六', '日'];
}
