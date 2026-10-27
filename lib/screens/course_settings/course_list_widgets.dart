import 'package:flutter/material.dart';

import '../../models/course.dart';
import '../../resources/app_strings.dart';
import '../../services/schedule_scope.dart';
import '../../services/schedule_utils.dart';

/// 课程设置页的「单门课程卡片」与批量操作条。
///
/// 拆分自 `course_settings_page.dart`（原文件 1245 行）。

class CourseListCard extends StatelessWidget {
  const CourseListCard({
    required this.course,
    required this.batchDeleteMode,
    required this.selected,
    required this.onSelectChanged,
    required this.onEdit,
    required this.onColor,
    required this.onDelete,
    super.key,
  });

  final Course course;
  final bool batchDeleteMode;
  final bool selected;
  final ValueChanged<bool> onSelectChanged;
  final VoidCallback onEdit;
  final VoidCallback onColor;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final store = ScheduleScope.of(context);
    final timeRange = ScheduleUtils.timeRange(store.settings, course);

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 16),
      child: Row(
        children: [
          if (batchDeleteMode)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: IconButton(
                onPressed: () => onSelectChanged(!selected),
                icon: Icon(
                  selected ? Icons.delete : Icons.delete_outline,
                  color: selected
                      ? const Color(0xffb3304a)
                      : const Color(0xff6b4f5a),
                ),
              ),
            ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xffffe9ef)
                    : Theme.of(context).colorScheme.surface,
                border: Border.all(color: const Color(0xfff7d9e2)),
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0f172033),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 5,
                        height: 38,
                        margin: const EdgeInsets.only(right: 12, top: 2),
                        decoration: BoxDecoration(
                          color: ScheduleUtils.colorForCourse(course),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          course.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!batchDeleteMode)
                        PopupMenuButton<CourseItemMenu>(
                          icon: const Icon(
                            Icons.more_horiz,
                            color: Color(0xff6b4f5a),
                          ),
                          onSelected: (value) {
                            switch (value) {
                              case CourseItemMenu.edit:
                                onEdit();
                              case CourseItemMenu.color:
                                onColor();
                              case CourseItemMenu.delete:
                                onDelete();
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: CourseItemMenu.edit,
                              child: Text(AppStrings.edit),
                            ),
                            PopupMenuItem(
                              value: CourseItemMenu.color,
                              child: Text(AppStrings.color),
                            ),
                            PopupMenuItem(
                              value: CourseItemMenu.delete,
                              child: Text(AppStrings.delete),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  InfoLine(
                    label: AppStrings.weekRangeLabel,
                    value: course.weekText,
                  ),
                  InfoLine(
                    label: AppStrings.classTimeLabel,
                    value: timeRange.isEmpty
                        ? ScheduleUtils.dayLabels[course.dayOfWeek - 1]
                        : '${ScheduleUtils.dayLabels[course.dayOfWeek - 1]}  $timeRange',
                  ),
                  InfoLine(
                    label: AppStrings.courseLocationLabel,
                    value: course.location,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum CourseItemMenu { edit, color, delete }

class InfoLine extends StatelessWidget {
  const InfoLine({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Color(0xff6b4f5a))),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              value.isEmpty ? AppStrings.notSet : value,
              style: const TextStyle(color: Color(0xff6b4f5a)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class BatchDeleteBar extends StatelessWidget {
  const BatchDeleteBar({
    required this.allSelected,
    required this.onSelectAll,
    required this.onConfirm,
    super.key,
  });

  final bool allSelected;
  final ValueChanged<bool> onSelectAll;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 12,
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 50,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Checkbox(
                  value: allSelected,
                  onChanged: (value) => onSelectAll(value ?? false),
                ),
                const Text(
                  AppStrings.selectAll,
                  style: TextStyle(fontSize: 16),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onConfirm,
                  child: const Text(
                    AppStrings.confirmDelete,
                    style: TextStyle(
                      color: Color(0xffb3304a),
                      fontWeight: FontWeight.bold,
                    ),
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
