import 'package:flutter/material.dart';

import '../resources/app_colors.dart';
import '../resources/app_metrics.dart';
import '../resources/app_strings.dart';
import '../services/schedule_scope.dart';
import '../services/schedule_utils.dart';
import '../widgets/app_icons.dart';
import '../widgets/feedback.dart';
import '../widgets/soft_ui.dart';
import 'course_editor.dart';

/// 课程管理：一屏看完全部课程，支持逐条修改与批量删除。
class CourseSettingsPage extends StatefulWidget {
  const CourseSettingsPage({super.key});

  @override
  State<CourseSettingsPage> createState() => _CourseSettingsPageState();
}

class _CourseSettingsPageState extends State<CourseSettingsPage> {
  final Set<int> _selected = {};

  @override
  Widget build(BuildContext context) {
    final store = ScheduleScope.of(context);
    final courses = store.courses;
    final settings = store.settings;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text(AppStrings.courseSettingsTitle),
        actions: [
          IconButton(
            tooltip: AppStrings.addCourse,
            icon: const Icon(AppIcons.plus),
            onPressed: () => showCourseEditor(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: courses.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(AppMetrics.sp5),
                    child: SoftCard(
                      child: EmptyPanel(
                        title: AppStrings.emptyScheduleTitle,
                        body: AppStrings.emptyScheduleCopy,
                        action: PrimaryButton(
                          label: AppStrings.emptyScheduleAddManually,
                          onPressed: () => showCourseEditor(context),
                        ),
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppMetrics.sp5,
                      AppMetrics.sp4,
                      AppMetrics.sp5,
                      AppMetrics.sp6,
                    ),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              AppStrings.totalCourses(courses.length),
                              style: const TextStyle(
                                fontSize: AppMetrics.small,
                                color: AppColors.ink500,
                              ),
                            ),
                          ),
                          if (_selected.isNotEmpty)
                            DangerButton(
                              label:
                                  '${AppStrings.batchDelete}（${_selected.length}）',
                              icon: AppIcons.delete,
                              onPressed: _deleteSelected,
                            ),
                        ],
                      ),
                      const SizedBox(height: AppMetrics.sp3),
                      for (final course in courses)
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppMetrics.sp2,
                          ),
                          child: SoftCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppMetrics.sp3,
                              vertical: AppMetrics.sp2,
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: _selected.contains(course.id),
                                  onChanged: (checked) => setState(() {
                                    if (checked == true) {
                                      _selected.add(course.id);
                                    } else {
                                      _selected.remove(course.id);
                                    }
                                  }),
                                ),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => showCourseEditor(
                                      context,
                                      course: course,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            course.name,
                                            style: const TextStyle(
                                              fontSize: AppMetrics.body,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.ink900,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            [
                                                  AppStrings
                                                      .fullWeekdays[(course
                                                              .dayOfWeek -
                                                          1)
                                                      .clamp(0, 6)],
                                                  AppStrings.lessonRangeText(
                                                    course.startLesson,
                                                    course.endLesson,
                                                  ),
                                                  ScheduleUtils.timeRange(
                                                    settings,
                                                    course,
                                                  ),
                                                  if (course.location
                                                      .trim()
                                                      .isNotEmpty)
                                                    course.location.trim(),
                                                  course.weekText,
                                                ]
                                                .where(
                                                  (value) => value.isNotEmpty,
                                                )
                                                .join(' · '),
                                            style: const TextStyle(
                                              fontSize: AppMetrics.tiny,
                                              color: AppColors.ink500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: AppStrings.editCourse,
                                  icon: const Icon(AppIcons.edit, size: 18),
                                  onPressed: () =>
                                      showCourseEditor(context, course: course),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: AppMetrics.sp4),
                      QuietButton(
                        label: AppStrings.exportJson,
                        icon: AppIcons.download,
                        onPressed: () {
                          final json = ScheduleScope.of(
                            context,
                          ).exportCoursesJson();
                          copyWithNotice(context, json.isEmpty ? '{}' : json);
                        },
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteSelected() async {
    final count = _selected.length;
    final confirmed = await confirmDanger(
      context,
      title: AppStrings.deleteCoursesTitle,
      message: AppStrings.deleteCoursesMessage(count),
      confirmLabel: AppStrings.confirmDelete,
    );
    if (!confirmed || !mounted) {
      return;
    }
    final store = ScheduleScope.of(context);
    await store.deleteCourses({..._selected});
    if (mounted) {
      setState(_selected.clear);
      AppNotice.success(context, AppStrings.coursesDeleted);
    }
  }
}
