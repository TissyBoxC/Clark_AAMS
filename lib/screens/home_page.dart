import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_settings.dart';
import '../models/app_version.dart';
import '../models/course.dart';
import '../services/auth_session.dart';
import '../services/clark_backend_api.dart';
import '../services/lesson_time_defaults.dart';
import '../services/schedule_scope.dart';
import '../services/schedule_utils.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/top_bar.dart';
import 'about_page.dart';
import 'app_settings_page.dart';
import 'auth_page.dart';
import 'chaoxing_homework_page.dart';
import 'course_settings_page.dart';
import 'term_lesson_setup_page.dart';
import 'welcome_page.dart';

const _ink = Color(0xff2b2545);
const _muted = Color(0xff81799f);
const _lavender = Color(0xff7c6cff);
const _pink = Color(0xffff7eb6);
const _cream = Color(0xfffffbff);
const _panel = Color(0xffffffff);
const _line = Color(0xffe8e3ff);

String _weekLabel(int week) => '第$week 周';
String _lessonRangeLabel(int startLesson, int endLesson) =>
    '第$startLesson-$endLesson 节';

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
      backgroundColor: _cream,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xfffffbff), Color(0xfff4f1ff), Color(0xfffff7fb)],
          ),
        ),
        child: IndexedStack(
          index: _selectedTab,
          children: [
            _HomeTab(onOpenSchedule: () => setState(() => _selectedTab = 1)),
            _ScheduleTab(
              selectedWeek: _selectedWeek,
              onWeekChanged: (value) => setState(() => _selectedWeek = value),
            ),
            const _MineTab(),
          ],
        ),
      ),
      bottomNavigationBar: _IllustratedBottomBar(
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
          title: '设置第一周第一天',
          subtitle: '设置后即可自动计算当前周数；节次时间可选填，用于桌面小组件判断下一节课。',
          confirmText: '保存设置',
          cancelText: '稍后设置',
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
      // Version checks must not block the timetable when the backend is down.
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
                  child: const Text('稍后再说'),
                ),
              FilledButton(
                onPressed: () => _openDownload(version),
                child: const Text('去更新'),
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

class _IllustratedBottomBar extends StatelessWidget {
  const _IllustratedBottomBar({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _items = <_NavArtSpec>[
    _NavArtSpec(
      label: '首页',
      idleAsset: 'assets/nav/nav_home_idle.png',
      activeAsset: 'assets/nav/nav_home_active.png',
    ),
    _NavArtSpec(
      label: '课程表',
      idleAsset: 'assets/nav/nav_schedule_idle.png',
      activeAsset: 'assets/nav/nav_schedule_active.png',
    ),
    _NavArtSpec(
      label: '我的',
      idleAsset: 'assets/nav/nav_mine_idle.png',
      activeAsset: 'assets/nav/nav_mine_active.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(240),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white),
            boxShadow: const [
              BoxShadow(
                color: Color(0x160b0550),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: SizedBox(
            height: 54,
            child: Row(
              children: [
                for (var index = 0; index < _items.length; index++)
                  Expanded(
                    child: _NavArtButton(
                      spec: _items[index],
                      selected: selectedIndex == index,
                      onTap: () => onSelected(index),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavArtSpec {
  const _NavArtSpec({
    required this.label,
    required this.idleAsset,
    required this.activeAsset,
  });

  final String label;
  final String idleAsset;
  final String activeAsset;
}

class _NavArtButton extends StatelessWidget {
  const _NavArtButton({
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  final _NavArtSpec spec;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final image = selected ? spec.activeAsset : spec.idleAsset;
    return Semantics(
      button: true,
      selected: selected,
      label: spec.label,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          margin: EdgeInsets.fromLTRB(5, selected ? 4 : 7, 5, 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: selected
                ? const Color(0xfff2efff)
                : Colors.white.withAlpha(0),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 28,
                child: Center(
                  child: AnimatedScale(
                    scale: selected ? 1.04 : 0.9,
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutBack,
                    child: AnimatedOpacity(
                      opacity: selected ? 1 : 0.58,
                      duration: const Duration(milliseconds: 220),
                      child: Image.asset(
                        image,
                        height: 24,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 1),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                style: TextStyle(
                  color: selected ? _lavender : _muted.withAlpha(180),
                  fontSize: selected ? 10 : 9,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  height: 1,
                ),
                child: Text(spec.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({required this.onOpenSchedule});

  final VoidCallback onOpenSchedule;

  @override
  Widget build(BuildContext context) {
    final store = ScheduleScope.of(context);
    final settings = store.settings;
    final today = DateTime.now();
    final week = ScheduleUtils.currentWeek(settings, today);
    final allTodayCourses =
        store.courses
            .where(
              (course) =>
                  course.matchesWeek(week) && course.dayOfWeek == today.weekday,
            )
            .toList()
          ..sort((a, b) => a.startLesson.compareTo(b.startLesson));
    final todayCourses = allTodayCourses
        .where((course) => _isCourseNotFinished(settings, course, today))
        .toList();
    final todayStatusText = allTodayCourses.isEmpty ? '今天没有课程安排' : '今天的课已经上完了';

    return Column(
      children: [
        TopBar(
          title: '珂拉课程表',
          titleIcon: Image.asset('assets/logo/logo.png', width: 28, height: 28),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
            children: [
              _HomeHeroCard(
                week: week,
                todayCourseCount: todayCourses.length,
                onOpenSchedule: onOpenSchedule,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      label: '课程总数',
                      value: '${store.courses.length}',
                      color: _lavender,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricTile(
                      label: '本周',
                      value: _weekLabel(week),
                      color: _pink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionTitle(
                title: '今日课程',
                action: allTodayCourses.isEmpty ? null : '查看课表',
                onAction: allTodayCourses.isEmpty ? null : onOpenSchedule,
              ),
              const SizedBox(height: 10),
              if (todayCourses.isEmpty)
                _EmptyTodayCard(message: todayStatusText)
              else
                for (final course in todayCourses)
                  _TodayCourseTile(course: course, settings: settings),
            ],
          ),
        ),
      ],
    );
  }

  bool _isCourseNotFinished(
    AppSettingsModel settings,
    Course course,
    DateTime now,
  ) {
    final endMinute = _minuteForLesson(settings, course.endLesson);
    if (endMinute == null) {
      return true;
    }
    final currentMinute = now.hour * 60 + now.minute;
    return currentMinute <= endMinute;
  }

  int? _minuteForLesson(AppSettingsModel settings, int lesson) {
    final index = lesson - 1;
    if (index < 0 || index >= settings.startTimes.length) {
      return null;
    }
    final raw = settings.startTimes[index].trim().replaceAll('：', ':');
    if (raw.isEmpty) {
      return null;
    }
    final parts = raw.split(':');
    if (parts.length != 2) {
      return null;
    }
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return null;
    }
    if (hour < 0 || hour > 24 || minute < 0 || minute > 59) {
      return null;
    }
    if (hour == 24 && minute != 0) {
      return null;
    }
    return hour * 60 + minute + settings.durationPerLesson;
  }
}

class _HomeHeroCard extends StatelessWidget {
  const _HomeHeroCard({
    required this.week,
    required this.todayCourseCount,
    required this.onOpenSchedule,
  });

  final int week;
  final int todayCourseCount;
  final VoidCallback onOpenSchedule;

  @override
  Widget build(BuildContext context) {
    return _SoftPanel(
      padding: const EdgeInsets.fromLTRB(18, 16, 6, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '今天也要稳稳上课',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_weekLabel(week)} · 今日待上 $todayCourseCount 节课',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _lavender,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onPressed: onOpenSchedule,
                  child: const Text('打开课表'),
                ),
              ],
            ),
          ),
          Image.asset(
            'assets/nav/nav_home_active.png',
            width: 142,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ],
      ),
    );
  }
}

class _SoftPanel extends StatelessWidget {
  const _SoftPanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: _panel.withAlpha(238),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 1.4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x160b0550),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return _SoftPanel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: _ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    );
  }
}

class _EmptyTodayCard extends StatelessWidget {
  const _EmptyTodayCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _SoftPanel(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Image.asset(
            'assets/nav/nav_schedule_idle.png',
            width: 74,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: _ink,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayCourseTile extends StatelessWidget {
  const _TodayCourseTile({required this.course, required this.settings});

  final Course course;
  final AppSettingsModel settings;

  @override
  Widget build(BuildContext context) {
    final color = ScheduleUtils.colorForCourse(course);
    final time = ScheduleUtils.timeRange(settings, course);
    return _SoftPanel(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 54,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  [
                    _lessonRangeLabel(course.startLesson, course.endLesson),
                    if (time.isNotEmpty) time,
                    if (course.location.isNotEmpty) course.location,
                  ].join(' / '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleTab extends StatelessWidget {
  const _ScheduleTab({required this.selectedWeek, required this.onWeekChanged});

  final int? selectedWeek;
  final ValueChanged<int> onWeekChanged;

  @override
  Widget build(BuildContext context) {
    final store = ScheduleScope.of(context);
    final settings = store.settings;
    final week =
        (selectedWeek ?? ScheduleUtils.currentWeek(settings, DateTime.now()))
            .clamp(1, settings.maxWeeks);
    final monday = ScheduleUtils.weekMonday(settings, week);

    return Column(
      children: [
        const TopBar(title: '课程表'),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 2, 18, 12),
          child: _ScheduleHeaderCard(
            week: week,
            maxWeeks: settings.maxWeeks,
            onWeekChanged: onWeekChanged,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
            child: _SoftPanel(
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
              child: Column(
                children: [
                  _WeekHeader(monday: monday),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      child: _ScheduleTable(
                        courses: store.courses,
                        selectedWeek: week,
                        maxLessons: ScheduleUtils.lessonCount(
                          settings,
                          store.courses,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScheduleHeaderCard extends StatelessWidget {
  const _ScheduleHeaderCard({
    required this.week,
    required this.maxWeeks,
    required this.onWeekChanged,
  });

  final int week;
  final int maxWeeks;
  final ValueChanged<int> onWeekChanged;

  @override
  Widget build(BuildContext context) {
    return _SoftPanel(
      padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
      child: Row(
        children: [
          Image.asset(
            'assets/nav/nav_schedule_active.png',
            width: 88,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              '本周课程',
              style: TextStyle(
                color: _ink,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Container(
            width: 126,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xfff2efff),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: _line),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: week,
                isExpanded: true,
                menuMaxHeight: 210,
                borderRadius: BorderRadius.circular(18),
                icon: const Icon(Icons.expand_more, color: _lavender),
                dropdownColor: Colors.white,
                style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w800,
                ),
                items: [
                  for (var value = 1; value <= maxWeeks; value++)
                    DropdownMenuItem(
                      value: value,
                      child: Text(_weekLabel(value)),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    onWeekChanged(value);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MineTab extends StatelessWidget {
  const _MineTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TopBar(
          title: '我的',
          trailing: AnimatedBuilder(
            animation: AuthSession.instance,
            builder: (context, _) => _AuthEntryButton(
              authenticated: AuthSession.instance.isAuthenticated,
              label: AuthSession.instance.isAuthenticated
                  ? AuthSession.instance.user.displayName
                  : '登录/注册',
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
            children: [
              const _MineProfileCard(),
              const SizedBox(height: 14),
              _MineActionTile(
                icon: Icons.widgets_outlined,
                title: '桌面小组件',
                subtitle: '查看不同系统的添加方式',
                color: const Color(0xff6d64ff),
                onTap: _pinHomeWidget,
              ),
              _MineActionTile(
                icon: Icons.school_outlined,
                title: '学习通作业辅助',
                subtitle: '需登录后使用自动化处理作业流程',
                color: _pink,
                onTap: _openChaoxingHomework,
              ),
              const _MineActionTile(
                icon: Icons.edit_calendar_outlined,
                title: '课程设置',
                subtitle: '导入、编辑和导出课程',
                color: _lavender,
                page: CourseSettingsPage(),
              ),
              _MineActionTile(
                icon: Icons.settings_outlined,
                title: '应用设置',
                subtitle: '提醒时间、节次和偏好设置',
                color: Color(0xff5bb6ff),
                page: AppSettingsPage(),
              ),
              _MineActionTile(
                icon: Icons.info_outline,
                title: '关于',
                subtitle: '版本信息与项目说明',
                color: Color(0xffffc45b),
                page: AboutPage(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Future<void> _pinHomeWidget(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('添加小组件'),
          content: const Text('不同系统添加小组件方式不同，请前往用户手册查看符合你系统的添加方式。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await launchUrl(
                  Uri.parse('https://clarkhub.cn'),
                  mode: LaunchMode.externalApplication,
                );
              },
              child: const Text('前往官网'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _openChaoxingHomework(BuildContext context) async {
    final session = AuthSession.instance;
    if (session.isAuthenticated) {
      try {
        await session.refresh();
      } catch (_) {
        // Keep the local state and let the backend validate on actual request.
      }
    }
    if (!context.mounted) {
      return;
    }
    if (!session.isAuthenticated) {
      AppSnackBar.show(
        context,
        '请先登录后再使用学习通作业辅助',
        action: SnackBarAction(
          label: '去登录',
          onPressed: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const AuthPage()));
          },
        ),
      );
      return;
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ChaoxingHomeworkPage()));
  }
}

class _AuthEntryButton extends StatelessWidget {
  const _AuthEntryButton({required this.authenticated, required this.label});

  final bool authenticated;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AuthPage()));
      },
      icon: Icon(authenticated ? Icons.account_circle : Icons.login, size: 18),
      label: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 82),
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      style: TextButton.styleFrom(
        foregroundColor: _lavender,
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }
}

class _MineProfileCard extends StatelessWidget {
  const _MineProfileCard();

  @override
  Widget build(BuildContext context) {
    return _SoftPanel(
      padding: const EdgeInsets.fromLTRB(18, 12, 10, 10),
      child: Row(
        children: [
          Expanded(
            child: AnimatedBuilder(
              animation: AuthSession.instance,
              builder: (context, _) {
                final user = AuthSession.instance.user;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '我的空间',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user.isAuthenticated
                          ? '${user.displayName}，已使用 ${user.questionAnalysisCount} 次做题辅助'
                          : '课程、提醒和工具都在这里',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          AnimatedBuilder(
            animation: AuthSession.instance,
            builder: (context, _) =>
                _MineAvatar(email: AuthSession.instance.user.email),
          ),
        ],
      ),
    );
  }
}

class _MineAvatar extends StatelessWidget {
  const _MineAvatar({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    final uin = _qqUin(email);
    if (uin == null) {
      return Image(
        image: const AssetImage('assets/nav/nav_mine_active.png'),
        width: 132,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      );
    }
    return Container(
      width: 92,
      height: 92,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: _line, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x180b0550),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.network(
          'https://q1.qlogo.cn/g?b=qq&nk=$uin&s=640',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(
              'assets/nav/nav_mine_active.png',
              fit: BoxFit.contain,
            );
          },
        ),
      ),
    );
  }

  static String? _qqUin(String email) {
    final normalized = email.trim().toLowerCase();
    if (!normalized.endsWith('@qq.com')) {
      return null;
    }
    final value = normalized.substring(0, normalized.length - 7);
    return RegExp(r'^\d{5,12}$').hasMatch(value) ? value : null;
  }
}

class _MineActionTile extends StatelessWidget {
  const _MineActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.page,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Widget? page;
  final Future<void> Function(BuildContext context)? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _SoftPanel(
        padding: EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              final customTap = onTap;
              if (customTap != null) {
                customTap(context);
                return;
              }
              final target = page;
              if (target != null) {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => target));
              }
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color.withAlpha(34),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: _muted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WeekHeader extends StatelessWidget {
  const _WeekHeader({required this.monday});

  final DateTime monday;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    return Row(
      children: [
        SizedBox(
          width: 38,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Text(
              '${monday.month}月',
              style: const TextStyle(
                color: _muted,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        for (var index = 0; index < 7; index++)
          Expanded(
            child: _DayHeader(
              label: ScheduleUtils.dayLabels[index],
              date: monday.add(Duration(days: index)),
              isToday: _sameDay(today, monday.add(Duration(days: index))),
            ),
          ),
      ],
    );
  }

  static bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({
    required this.label,
    required this.date,
    required this.isToday,
  });

  final String label;
  final DateTime date;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isToday ? const Color(0xfff0ecff) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: isToday ? Border.all(color: _line) : null,
      ),
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: isToday ? _lavender : _muted,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            '${date.day}',
            style: TextStyle(
              color: isToday ? _lavender : _ink,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleTable extends StatelessWidget {
  const _ScheduleTable({
    required this.courses,
    required this.selectedWeek,
    required this.maxLessons,
  });

  static const _slotHeight = 64.0;

  final List<Course> courses;
  final int selectedWeek;
  final int maxLessons;

  @override
  Widget build(BuildContext context) {
    final visibleCourses = courses
        .where((course) => course.matchesWeek(selectedWeek))
        .toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 38,
          child: Column(
            children: [
              for (var lesson = 1; lesson <= maxLessons; lesson++)
                SizedBox(
                  height: _slotHeight,
                  child: Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.symmetric(
                      vertical: 2,
                      horizontal: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xfff2efff),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _line),
                    ),
                    child: Text(
                      '$lesson',
                      style: const TextStyle(
                        color: _lavender,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        for (var day = 1; day <= 7; day++)
          Expanded(
            child: _DayColumn(
              courses: visibleCourses
                  .where((course) => course.dayOfWeek == day)
                  .toList(),
              maxLessons: maxLessons,
            ),
          ),
      ],
    );
  }
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({required this.courses, required this.maxLessons});

  static const _slotHeight = 64.0;

  final List<Course> courses;
  final int maxLessons;

  @override
  Widget build(BuildContext context) {
    final sorted = [...courses]
      ..sort((a, b) => a.startLesson.compareTo(b.startLesson));
    return SizedBox(
      height: _slotHeight * maxLessons,
      child: Stack(
        children: [
          for (final course in sorted)
            if (course.startLesson <= maxLessons && course.endLesson >= 1)
              Positioned(
                left: 0,
                right: 0,
                top: _topFor(course),
                height: _heightFor(course),
                child: _CourseBlock(course: course),
              ),
        ],
      ),
    );
  }

  double _topFor(Course course) {
    return (course.startLesson.clamp(1, maxLessons).toInt() - 1) * _slotHeight;
  }

  double _heightFor(Course course) {
    final start = course.startLesson.clamp(1, maxLessons).toInt();
    final end = course.endLesson.clamp(1, maxLessons).toInt();
    return (end - start + 1) * _slotHeight;
  }
}

class _CourseBlock extends StatelessWidget {
  const _CourseBlock({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    final store = ScheduleScope.of(context);
    final color = ScheduleUtils.colorForCourse(course);
    final foreground = color.computeLuminance() > 0.65
        ? Colors.black87
        : Colors.white;
    final location = course.location.trim();
    final showLocation = course.duration > 1 && location.isNotEmpty;

    return Container(
      margin: const EdgeInsets.fromLTRB(2, 3, 2, 3),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        shadowColor: color.withAlpha(70),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _showLessonInfo(context, store.settings, course),
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.name,
                  maxLines: showLocation ? 2 : course.duration * 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    height: 1.18,
                  ),
                ),
                if (showLocation) ...[
                  const SizedBox(height: 3),
                  Text(
                    location,
                    maxLines: course.duration * 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground.withAlpha(220),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLessonInfo(
    BuildContext context,
    AppSettingsModel settings,
    Course course,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(course.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(course.weekText),
              const SizedBox(height: 6),
              Text(
                '${ScheduleUtils.dayLabels[course.dayOfWeek - 1]}  ${_lessonRangeLabel(course.startLesson, course.endLesson)}',
              ),
              const SizedBox(height: 6),
              Text(ScheduleUtils.timeRange(settings, course)),
              const SizedBox(height: 6),
              if (course.teacher.isNotEmpty) ...[
                Text(course.teacher),
                const SizedBox(height: 6),
              ],
              if (course.rawTime.isNotEmpty) ...[
                Text(course.rawTime),
                const SizedBox(height: 6),
              ],
              Text(course.location.isEmpty ? '未设置地点' : course.location),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }
}
