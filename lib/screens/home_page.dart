import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../models/course.dart';
import '../services/schedule_scope.dart';
import '../services/schedule_utils.dart';
import '../widgets/top_bar.dart';
import 'about_page.dart';
import 'app_settings_page.dart';
import 'course_settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int? _selectedWeek;
  String? _termStartSnapshot;
  bool _askedForTermStart = false;

  @override
  Widget build(BuildContext context) {
    final store = ScheduleScope.of(context);
    final settings = store.settings;
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
            title: '课程表',
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
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: const Color(0xffd9e5e2)),
              ),
              child: DropdownButton<int>(
                value: week,
                underline: const SizedBox.shrink(),
                menuMaxHeight: 170,
                borderRadius: BorderRadius.circular(10),
                items: [
                  for (var value = 1; value <= settings.maxWeeks; value++)
                    DropdownMenuItem(value: value, child: Text('第 $value 周')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedWeek = value);
                  }
                },
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

  final List<Course> courses;
  final int maxLessons;

  @override
  Widget build(BuildContext context) {
    final sorted = [...courses]
      ..sort((a, b) => a.startLesson.compareTo(b.startLesson));
    final children = <Widget>[];
    var currentLesson = 1;
    for (final course in sorted) {
      if (course.startLesson > currentLesson) {
        children.add(
          _EmptyLessonBlock(duration: course.startLesson - currentLesson),
        );
      }
      children.add(_CourseBlock(course: course));
      currentLesson = course.endLesson + 1;
    }
    if (currentLesson <= maxLessons) {
      children.add(_EmptyLessonBlock(duration: maxLessons - currentLesson + 1));
    }
    return Column(children: children);
  }
}

class _EmptyLessonBlock extends StatelessWidget {
  const _EmptyLessonBlock({required this.duration});

  static const _slotHeight = 64.0;

  final int duration;

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: _slotHeight * duration);
  }
}

class _CourseBlock extends StatelessWidget {
  const _CourseBlock({required this.course});

  static const _slotHeight = 64.0;

  final Course course;

  @override
  Widget build(BuildContext context) {
    final store = ScheduleScope.of(context);
    final color = ScheduleUtils.colorForCourse(course);
    final foreground = color.computeLuminance() > 0.65
        ? Colors.black87
        : Colors.white;

    return Container(
      height: _slotHeight * course.duration,
      margin: const EdgeInsets.fromLTRB(2, 2, 2, 2),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _showLessonInfo(context, store.settings, course),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Text(
              '${course.name} - \n${course.location}',
              maxLines: course.duration * 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                height: 1.18,
              ),
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
