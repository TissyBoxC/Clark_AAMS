import 'package:flutter/material.dart';

import '../models/course.dart';
import '../services/schedule_utils.dart';

class CourseFormDialog extends StatefulWidget {
  const CourseFormDialog({
    super.key,
    required this.maxWeeks,
    required this.maxLessons,
    this.initialCourse,
  });

  final int maxWeeks;
  final int maxLessons;
  final Course? initialCourse;

  @override
  State<CourseFormDialog> createState() => _CourseFormDialogState();
}

class _CourseFormDialogState extends State<CourseFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  late int _startWeek;
  late int _endWeek;
  late int _dayOfWeek;
  late int _startLesson;
  late int _endLesson;

  @override
  void initState() {
    super.initState();
    final course = widget.initialCourse;
    _nameController = TextEditingController(text: course?.name ?? '');
    _locationController = TextEditingController(text: course?.location ?? '');
    _startWeek = course?.startWeek ?? 1;
    _endWeek = course?.endWeek ?? widget.maxWeeks;
    _dayOfWeek = course?.dayOfWeek ?? 1;
    _startLesson = course?.startLesson ?? 1;
    _endLesson = course?.endLesson ?? 1;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialCourse == null ? '添加课程' : '修改课程'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: '课程名称'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Dropdown<int>(
                    value: _startWeek,
                    items: [
                      for (var week = 1; week <= widget.maxWeeks; week++)
                        DropdownMenuItem(value: week, child: Text('第 $week 周')),
                    ],
                    onChanged: (value) => setState(() => _startWeek = value),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('至'),
                ),
                Expanded(
                  child: _Dropdown<int>(
                    value: _endWeek,
                    items: [
                      for (var week = widget.maxWeeks; week >= 1; week--)
                        DropdownMenuItem(value: week, child: Text('第 $week 周')),
                    ],
                    onChanged: (value) => setState(() => _endWeek = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: _Dropdown<int>(
                value: _dayOfWeek,
                items: [
                  for (var day = 1; day <= 7; day++)
                    DropdownMenuItem(
                      value: day,
                      child: Text(ScheduleUtils.dayLabels[day - 1]),
                    ),
                ],
                onChanged: (value) => setState(() => _dayOfWeek = value),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Dropdown<int>(
                    value: _startLesson,
                    items: [
                      for (
                        var lesson = 1;
                        lesson <= widget.maxLessons;
                        lesson++
                      )
                        DropdownMenuItem(
                          value: lesson,
                          child: Text('第 $lesson 节'),
                        ),
                    ],
                    onChanged: (value) => setState(() => _startLesson = value),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('至'),
                ),
                Expanded(
                  child: _Dropdown<int>(
                    value: _endLesson,
                    items: [
                      for (
                        var lesson = 1;
                        lesson <= widget.maxLessons;
                        lesson++
                      )
                        DropdownMenuItem(
                          value: lesson,
                          child: Text('第 $lesson 节'),
                        ),
                    ],
                    onChanged: (value) => setState(() => _endLesson = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(hintText: '课程地点'),
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [FilledButton(onPressed: _save, child: const Text('保存'))],
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _toast('请输入课程名称');
      return;
    }
    if (_startWeek > _endWeek) {
      _toast('起始周不能大于结束周');
      return;
    }
    if (_startLesson > _endLesson) {
      _toast('起始节次不能晚于结束节次');
      return;
    }
    Navigator.of(context).pop(
      Course(
        id: widget.initialCourse?.id ?? 0,
        name: name,
        startWeek: _startWeek,
        endWeek: _endWeek,
        dayOfWeek: _dayOfWeek,
        startLesson: _startLesson,
        endLesson: _endLesson,
        location: _locationController.text.trim(),
      ),
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<T>(
      value: value,
      isExpanded: true,
      items: items,
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}
