import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_version.dart';
import '../resources/app_strings.dart';
import '../services/clark_backend_api.dart';
import '../services/lesson_time_defaults.dart';
import '../services/schedule_scope.dart';
import '../services/schedule_utils.dart';
import 'home/home_chrome.dart';
import 'home/home_mine_tab.dart';
import 'home/home_schedule_tab.dart';
import 'home/home_style.dart';
import 'home/home_tab.dart';
import 'term_lesson_setup_page.dart';
import 'welcome_page.dart';

/// 应用首页：三个 Tab（首页 / 课表 / 我的）+ 版本检查 + 学期起始日引导。
///
/// 拆分说明（P4-1）：这个文件原本 1570 行，混了主状态、20 多个私有 widget
/// 和大量配色常量。现在只保留「页面状态与编排」，
/// 三个 Tab 各自的 UI 移到 `home/` 子目录，
/// 共享配色与卡片容器移到 `home/home_style.dart` 与 `home/home_tab.dart`。
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedTab = 0;
  int? _selectedWeek;
  String? _termStartSnapshot;
  bool _askedForTermStart = false;
  bool _versionCheckStarted = false;

  @override
  Widget build(BuildContext context) {
    final store = ScheduleScope.of(context);
    final settings = store.settings;
    if (settings.schoolId.isEmpty || settings.isFirstLaunch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const WelcomePage()),
            (route) => false,
          );
        }
      });
      return const Scaffold(body: SizedBox.shrink());
    }
    if (!_versionCheckStarted) {
      _versionCheckStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _checkAppVersion();
        }
      });
    }
    if (!_askedForTermStart &&
        settings.termStartDate.isEmpty &&
        store.courses.isNotEmpty) {
      _askedForTermStart = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _promptForTermStartDate();
        }
      });
    }
    if (_termStartSnapshot != settings.termStartDate) {
      _selectedWeek = null;
      _termStartSnapshot = settings.termStartDate;
    }
    return Scaffold(
      backgroundColor: homeCream,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: homeBackgroundGradient,
          ),
        ),
        child: IndexedStack(
          index: _selectedTab,
          children: [
            HomeTab(onOpenSchedule: () => setState(() => _selectedTab = 1)),
            ScheduleTab(
              selectedWeek: _selectedWeek,
              onWeekChanged: (value) => setState(() => _selectedWeek = value),
            ),
            const MineTab(),
          ],
        ),
      ),
      bottomNavigationBar: HomeBottomBar(
        selectedIndex: _selectedTab,
        onSelected: (index) => setState(() => _selectedTab = index),
      ),
    );
  }

  Future<void> _promptForTermStartDate() async {
    final store = ScheduleScope.of(context);
    final defaults = await LessonTimeDefaults.resolve(
      store,
      courses: store.courses,
    );
    if (!mounted) {
      return;
    }
    final setup = await Navigator.of(context).push<TermLessonSetupResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => TermLessonSetupPage(
          initialTermStartDate: DateTime.now(),
          initialStartTimes: defaults.initialStartTimes,
          lessonCount: ScheduleUtils.lessonCount(store.settings, store.courses),
          title: AppStrings.setupFirstWeekFirstDayTitle,
          subtitle: AppStrings.setupFirstWeekFirstDaySubtitle,
          confirmText: AppStrings.saveSettings,
          cancelText: AppStrings.setupLater,
          lessonTimeProfiles: defaults.generalProfiles,
          lessonTimeNotice: defaults.notice,
        ),
      ),
    );
    if (setup == null) {
      return;
    }
    await store.updateSettings(
      store.settings.copyWith(
        termStartDate: ScheduleUtils.formatDate(setup.termStartDate),
        termMonth: setup.termStartDate.month,
        termDay: setup.termStartDate.day,
        startTimes: setup.startTimes,
      ),
    );
    if (mounted) {
      setState(() {
        _selectedWeek = null;
        _termStartSnapshot = null;
      });
    }
  }

  Future<void> _checkAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final version = await ClarkBackendApi.instance.checkVersion(
        platform: Platform.isAndroid
            ? 'android'
            : Platform.isIOS
            ? 'ios'
            : Platform.operatingSystem,
        currentVersion: info.version,
        currentBuild: int.tryParse(info.buildNumber),
        channel: 'stable',
      );
      if (!mounted ||
          !version.updateAvailable ||
          version.updateType == 'none') {
        return;
      }
      await _showUpdateDialog(version);
    } catch (_) {
      // 版本检查失败不能阻塞课表：后端不可用时静默跳过。
    }
  }

  Future<void> _showUpdateDialog(AppVersionInfo version) {
    final required = version.forceUpdate || version.updateType == 'required';
    return showDialog<void>(
      context: context,
      barrierDismissible: !required,
      builder: (context) {
        final notes = version.releaseNotes.join('\n');
        final content = [
          if (version.message.isNotEmpty) version.message,
          if (notes.isNotEmpty) '\n$notes',
        ].join('\n');
        return PopScope(
          canPop: !required,
          child: AlertDialog(
            title: Text(version.title),
            content: SingleChildScrollView(child: Text(content)),
            actions: [
              if (!required)
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(AppStrings.later),
                ),
              FilledButton(
                onPressed: () => _openDownload(version),
                child: const Text(AppStrings.updateNow),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openDownload(AppVersionInfo version) async {
    final source = version.primaryDownloadSource;
    final url = source?.url.isNotEmpty == true
        ? source!.url
        : version.releasePageUrl;
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
