import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_settings.dart';
import '../models/app_version.dart';
import '../models/course.dart';
import '../services/clark_backend_api.dart';
import '../services/schedule_scope.dart';
import '../services/schedule_utils.dart';
import '../widgets/top_bar.dart';
import 'about_page.dart';
import 'app_settings_page.dart';
import 'course_settings_page.dart';
import 'welcome_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
    final today = DateTime.now();
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
    final week = (_selectedWeek ?? ScheduleUtils.currentWeek(settings, today))
        .clamp(1, settings.maxWeeks);
    _selectedWeek = week;
    final monday = ScheduleUtils.weekMonday(settings, week);

    return Scaffold(
      backgroundColor: const Color(0xfff6f8fb),
      body: Column(
        children: [
          TopBar(
            title: '珂拉课程表',
            titleIcon: Image.asset(
              'assets/logo/logo.png',
              width: 28,
              height: 28,
            ),
            trailing: PopupMenuButton<_HomeMenu>(
              icon: const Icon(Icons.more_horiz, color: Color(0xff808080)),
              onSelected: (value) {
                final page = switch (value) {
                  _HomeMenu.courseSettings => const CourseSettingsPage(),
                  _HomeMenu.appSettings => const AppSettingsPage(),
                  _HomeMenu.about => const AboutPage(),
                };
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => page));
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: _HomeMenu.courseSettings,
                  child: Text('课程设置'),
                ),
                PopupMenuItem(
                  value: _HomeMenu.appSettings,
                  child: Text('应用设置'),
                ),
                PopupMenuItem(value: _HomeMenu.about, child: Text('关于')),
              ],
            ),
          ),
          Center(
            child: Container(
              width: 180,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: const Color(0xffd9e5e2)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: week,
                  isExpanded: true,
                  menuMaxHeight: 170,
                  borderRadius: BorderRadius.circular(10),
                  items: [
                    for (var value = 1; value <= settings.maxWeeks; value++)
                      DropdownMenuItem(
                        value: value,
                        child: Center(child: Text('第 $value 周')),
                      ),
                  ],
                  selectedItemBuilder: (context) => [
                    for (var value = 1; value <= settings.maxWeeks; value++)
                      Center(child: Text('第 $value 周')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedWeek = value);
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          _WeekHeader(monday: monday),
          const SizedBox(height: 5),
          Expanded(
            child: SingleChildScrollView(
              child: _ScheduleTable(
                courses: store.courses,
                selectedWeek: week,
                maxLessons: settings.startTimes.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _promptForTermStartDate() async {
    final store = ScheduleScope.of(context);
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: DateTime(today.year - 2),
      lastDate: DateTime(today.year + 2),
      helpText: '设置第一周第一天',
      cancelText: '稍后设置',
      confirmText: '确定',
    );
    if (picked == null) {
      return;
    }
    await store.updateSettings(
      store.settings.copyWith(
        termStartDate: ScheduleUtils.formatDate(picked),
        termMonth: picked.month,
        termDay: picked.day,
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

enum _HomeMenu { courseSettings, appSettings, about }

class _WeekHeader extends StatelessWidget {
  const _WeekHeader({required this.monday});

  final DateTime monday;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    return Row(
      children: [
        SizedBox(
          width: 42,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Text(
              '${monday.month}月',
              style: const TextStyle(fontWeight: FontWeight.bold),
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
        color: isToday ? const Color(0xffdff5ef) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: isToday
                  ? const Color(0xff0f766e)
                  : const Color(0xff1c1b1f),
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${date.day}',
            style: TextStyle(
              color: isToday
                  ? const Color(0xff0f766e)
                  : const Color(0xff808080),
              fontWeight: FontWeight.bold,
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
          width: 42,
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
                      color: const Color(0xff172033),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$lesson',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
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
      margin: const EdgeInsets.fromLTRB(2, 2, 2, 2),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _showLessonInfo(context, store.settings, course),
          child: Padding(
            padding: const EdgeInsets.all(5),
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
                    fontWeight: FontWeight.bold,
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
                      fontWeight: FontWeight.w600,
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
                '${ScheduleUtils.dayLabels[course.dayOfWeek - 1]}  第${course.startLesson}-${course.endLesson}节',
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
