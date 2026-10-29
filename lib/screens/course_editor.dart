import 'package:flutter/material.dart';

import '../models/course.dart';
import '../resources/app_colors.dart';
import '../resources/app_metrics.dart';
import '../resources/app_strings.dart';
import '../services/schedule_scope.dart';
import '../services/schedule_utils.dart';
import '../widgets/app_icons.dart';
import '../widgets/feedback.dart';
import '../widgets/soft_ui.dart';

/// 打开课程编辑面板；传 course 表示修改，不传表示新建。
Future<void> showCourseEditor(
  BuildContext context, {
  Course? course,
  int defaultWeek = 1,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) =>
        _CourseEditorSheet(course: course, defaultWeek: defaultWeek),
  );
}

class _CourseEditorSheet extends StatefulWidget {
  const _CourseEditorSheet({this.course, required this.defaultWeek});

  final Course? course;
  final int defaultWeek;

  @override
  State<_CourseEditorSheet> createState() => _CourseEditorSheetState();
}

class _CourseEditorSheetState extends State<_CourseEditorSheet> {
  late final TextEditingController _name;
  late final TextEditingController _location;
  late final TextEditingController _teacher;
  late int _dayOfWeek;
  late int _startLesson;
  late int _endLesson;
  late int _startWeek;
  late int _endWeek;
  late WeekRule _rule;
  String _error = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final course = widget.course;
    _name = TextEditingController(text: course?.name ?? '');
    _location = TextEditingController(text: course?.location ?? '');
    _teacher = TextEditingController(text: course?.teacher ?? '');
    _dayOfWeek = course?.dayOfWeek ?? 1;
    _startLesson = course?.startLesson ?? 1;
    _endLesson = course?.endLesson ?? 2;
    _startWeek = course?.weekPattern.firstWeek ?? widget.defaultWeek;
    _endWeek = course?.weekPattern.lastWeek ?? widget.defaultWeek;
    _rule = course?.weekPattern.rule ?? WeekRule.all;
  }

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _teacher.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = AppStrings.enterCourseName);
      return;
    }
    if (_startWeek > _endWeek) {
      setState(() => _error = AppStrings.startWeekAfterEndWeek);
      return;
    }
    if (_startLesson > _endLesson) {
      setState(() => _error = AppStrings.startLessonAfterEndLesson);
      return;
    }

    setState(() {
      _error = '';
      _saving = true;
    });

    final store = ScheduleScope.of(context);
    final pattern = WeekPattern(
      ranges: [WeekRange(_startWeek, _endWeek)],
      rule: _rule,
    );

    final draft = Course(
      id: widget.course?.id ?? 0,
      name: name,
      startWeek: _startWeek,
      endWeek: _endWeek,
      dayOfWeek: _dayOfWeek,
      startLesson: _startLesson,
      endLesson: _endLesson,
      location: _location.text.trim(),
      teacher: _teacher.text.trim(),
      weekPattern: pattern,
      colorValue: widget.course?.colorValue,
    );

    try {
      if (widget.course == null) {
        await store.addCourse(draft);
      } else {
        await store.updateCourse(widget.course!.id, draft);
      }
      if (mounted) {
        Navigator.of(context).pop();
        AppNotice.success(context, AppStrings.coursesAdded);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = AppStrings.backendRequestFailedFallback;
          _saving = false;
        });
      }
    }
  }

  Future<void> _delete() async {
    final course = widget.course;
    if (course == null) {
      return;
    }
    final confirmed = await confirmDanger(
      context,
      title: AppStrings.deleteCourseTitle,
      message: AppStrings.deleteCourseMessage(course.name),
      confirmLabel: AppStrings.delete,
    );
    if (!confirmed || !mounted) {
      return;
    }
    final store = ScheduleScope.of(context);
    await store.deleteCourse(course.id);
    if (mounted) {
      Navigator.of(context).pop();
      AppNotice.success(context, AppStrings.courseDeleted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = ScheduleScope.of(context);
    final settings = store.settings;
    final maxLessons = ScheduleUtils.lessonCount(settings, store.courses);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppMetrics.sp5,
          AppMetrics.sp4,
          AppMetrics.sp5,
          AppMetrics.sp5,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.course == null
                        ? AppStrings.addCourse
                        : AppStrings.editCourse,
                    style: const TextStyle(
                      fontSize: AppMetrics.h3,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: AppStrings.close,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(AppIcons.close),
                ),
              ],
            ),
            const SizedBox(height: AppMetrics.sp4),
            TextField(
              controller: _name,
              autofocus: widget.course == null,
              decoration: const InputDecoration(
                labelText: AppStrings.courseNameHint,
              ),
            ),
            const SizedBox(height: AppMetrics.sp3),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _dayOfWeek,
                    decoration: const InputDecoration(
                      labelText: AppStrings.week,
                    ),
                    items: [
                      for (var day = 1; day <= 7; day++)
                        DropdownMenuItem(
                          value: day,
                          child: Text(AppStrings.fullWeekdays[day - 1]),
                        ),
                    ],
                    onChanged: (value) =>
                        setState(() => _dayOfWeek = value ?? 1),
                  ),
                ),
                const SizedBox(width: AppMetrics.sp3),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _startLesson,
                    decoration: const InputDecoration(labelText: '起始节次'),
                    items: [
                      for (var lesson = 1; lesson <= maxLessons; lesson++)
                        DropdownMenuItem(
                          value: lesson,
                          child: Text(AppStrings.lessonPickerText(lesson)),
                        ),
                    ],
                    onChanged: (value) => setState(() {
                      _startLesson = value ?? 1;
                      if (_endLesson < _startLesson) {
                        _endLesson = _startLesson;
                      }
                    }),
                  ),
                ),
                const SizedBox(width: AppMetrics.sp3),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _endLesson,
                    decoration: const InputDecoration(labelText: '结束节次'),
                    items: [
                      for (var lesson = 1; lesson <= maxLessons; lesson++)
                        if (lesson >= _startLesson)
                          DropdownMenuItem(
                            value: lesson,
                            child: Text(AppStrings.lessonPickerText(lesson)),
                          ),
                    ],
                    onChanged: (value) =>
                        setState(() => _endLesson = value ?? _startLesson),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppMetrics.sp3),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _startWeek,
                    decoration: const InputDecoration(labelText: '起始周'),
                    items: [
                      for (var week = 1; week <= settings.maxWeeks; week++)
                        DropdownMenuItem(
                          value: week,
                          child: Text(AppStrings.weekPickerText(week)),
                        ),
                    ],
                    onChanged: (value) => setState(() {
                      _startWeek = value ?? 1;
                      if (_endWeek < _startWeek) {
                        _endWeek = _startWeek;
                      }
                    }),
                  ),
                ),
                const SizedBox(width: AppMetrics.sp3),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _endWeek,
                    decoration: const InputDecoration(labelText: '结束周'),
                    items: [
                      for (var week = 1; week <= settings.maxWeeks; week++)
                        if (week >= _startWeek)
                          DropdownMenuItem(
                            value: week,
                            child: Text(AppStrings.weekPickerText(week)),
                          ),
                    ],
                    onChanged: (value) =>
                        setState(() => _endWeek = value ?? _startWeek),
                  ),
                ),
                const SizedBox(width: AppMetrics.sp3),
                Expanded(
                  child: DropdownButtonFormField<WeekRule>(
                    initialValue: _rule,
                    decoration: const InputDecoration(labelText: '单双周'),
                    items: const [
                      DropdownMenuItem(value: WeekRule.all, child: Text('每周')),
                      DropdownMenuItem(value: WeekRule.odd, child: Text('单周')),
                      DropdownMenuItem(value: WeekRule.even, child: Text('双周')),
                    ],
                    onChanged: (value) =>
                        setState(() => _rule = value ?? WeekRule.all),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppMetrics.sp3),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _location,
                    decoration: const InputDecoration(
                      labelText: AppStrings.courseLocationHint,
                    ),
                  ),
                ),
                const SizedBox(width: AppMetrics.sp3),
                Expanded(
                  child: TextField(
                    controller: _teacher,
                    decoration: const InputDecoration(labelText: '老师'),
                  ),
                ),
              ],
            ),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: AppMetrics.sp3),
              NoticeBar(message: _error, tone: NoticeTone.error),
            ],
            const SizedBox(height: AppMetrics.sp5),
            Row(
              children: [
                if (widget.course != null)
                  DangerButton(
                    label: AppStrings.delete,
                    icon: AppIcons.delete,
                    onPressed: _delete,
                  ),
                const Spacer(),
                QuietButton(
                  label: AppStrings.cancel,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: AppMetrics.sp2),
                PrimaryButton(
                  label: AppStrings.save,
                  loading: _saving,
                  onPressed: _save,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
