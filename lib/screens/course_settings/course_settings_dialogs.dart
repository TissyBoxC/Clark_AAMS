import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/course.dart';
import '../../resources/app_strings.dart';
import '../../services/course_json_importer.dart';
import '../../services/schedule_utils.dart';
import '../../widgets/app_snack_bar.dart';

/// 课程设置页用到的各类对话框：批量添加、课程配色、识别结果配色、取件码。
///
/// 拆分自 `course_settings_page.dart`（原文件 1245 行）。
/// 这些对话框彼此独立、只依赖 AppStrings，因此适合单独成文件。

class BatchAddDialog extends StatefulWidget {
  const BatchAddDialog({required this.exportJson, super.key});

  final String exportJson;

  @override
  State<BatchAddDialog> createState() => BatchAddDialogState();
}

class BatchAddDialogState extends State<BatchAddDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.batchAddCoursesTitle),
      content: SizedBox(
        width: 520,
        child: TextField(
          controller: _controller,
          minLines: 10,
          maxLines: 10,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: AppStrings.courseJsonHint,
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _showHelp, child: const Text(AppStrings.help)),
        TextButton(
          onPressed: _exportJson,
          child: const Text(AppStrings.exportJson),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(onPressed: _save, child: const Text(AppStrings.save)),
      ],
    );
  }

  Future<void> _exportJson() async {
    await Clipboard.setData(ClipboardData(text: widget.exportJson));
    if (mounted) {
      AppSnackBar.show(context, AppStrings.copiedToClipboard);
    }
  }

  void _showHelp() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return const AlertDialog(
          title: Text(AppStrings.batchAddHelpTitle),
          content: SingleChildScrollView(
            child: Text(AppStrings.batchAddHelpExample),
          ),
        );
      },
    );
  }

  void _save() {
    try {
      final courses = CourseJsonImporter.parse(_controller.text);
      Navigator.of(context).pop(courses);
    } on FormatException catch (error) {
      _toast(error.message);
    } catch (_) {
      _toast(AppStrings.invalidJsonInput);
    }
  }

  void _toast(String message) {
    AppSnackBar.show(context, message);
  }
}

class CourseColorDialog extends StatelessWidget {
  const CourseColorDialog({required this.course, super.key});

  final Course course;

  @override
  Widget build(BuildContext context) {
    final current = ScheduleUtils.colorForCourse(course);
    return AlertDialog(
      title: Text(AppStrings.selectColorForCourse(course.name)),
      content: ColorGrid(
        selected: current,
        onSelected: (color) => Navigator.of(context).pop(color),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
      ],
    );
  }
}

class ImportedCourseColorsDialog extends StatefulWidget {
  const ImportedCourseColorsDialog({required this.courses, super.key});

  final List<Course> courses;

  @override
  State<ImportedCourseColorsDialog> createState() =>
      ImportedCourseColorsDialogState();
}

class ImportedCourseColorsDialogState
    extends State<ImportedCourseColorsDialog> {
  late List<Course> _courses;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _courses = [...widget.courses];
  }

  @override
  Widget build(BuildContext context) {
    final selectedCourse = _courses[_selectedIndex];
    return AlertDialog(
      title: const Text(AppStrings.setCourseColor),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _courses.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final course = _courses[index];
                  final selected = index == _selectedIndex;
                  return Material(
                    color: selected
                        ? const Color(0xffe6f3f1)
                        : const Color(0xfff8fafc),
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => setState(() => _selectedIndex = index),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 9,
                        ),
                        child: Row(
                          children: [
                            ColorDot(
                              color: ScheduleUtils.colorForCourse(course),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                course.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              ScheduleUtils.dayLabels[course.dayOfWeek - 1],
                              style: const TextStyle(color: Color(0xff6b4f5a)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                AppStrings.selectedCourseLabel(selectedCourse.name),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 10),
            ColorGrid(
              selected: ScheduleUtils.colorForCourse(selectedCourse),
              onSelected: (color) {
                setState(() {
                  _courses[_selectedIndex] = selectedCourse.copyWith(
                    colorValue: color.toARGB32(),
                  );
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_courses),
          child: const Text(AppStrings.confirmImport),
        ),
      ],
    );
  }
}

class ColorGrid extends StatelessWidget {
  const ColorGrid({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final Color selected;
  final ValueChanged<Color> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final color in ScheduleUtils.courseColors)
          Tooltip(
            message: '#${color.toARGB32().toRadixString(16).padLeft(8, '0')}',
            child: InkWell(
              onTap: () => onSelected(color),
              borderRadius: BorderRadius.circular(99),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.toARGB32() == selected.toARGB32()
                        ? Colors.black
                        : Colors.white,
                    width: color.toARGB32() == selected.toARGB32() ? 3 : 2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 8,
                      offset: Offset(0, 3),
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

class ColorDot extends StatelessWidget {
  const ColorDot({required this.color, super.key});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class PickupCodeDialog extends StatefulWidget {
  const PickupCodeDialog({super.key});

  @override
  State<PickupCodeDialog> createState() => PickupCodeDialogState();
}

class PickupCodeDialogState extends State<PickupCodeDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.enterPickupCodeTitle),
      content: TextField(
        controller: _controller,
        maxLength: 8,
        textCapitalization: TextCapitalization.characters,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: AppStrings.pickupCodeHint,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: () {
            final code = _controller.text.trim().toUpperCase();
            if (code.length != 8) {
              AppSnackBar.show(context, AppStrings.enterEightDigitPickupCode);
              return;
            }
            Navigator.of(context).pop(code);
          },
          child: const Text(AppStrings.import),
        ),
      ],
    );
  }
}
