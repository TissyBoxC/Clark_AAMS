import 'package:flutter/material.dart';

import '../models/course.dart';
import '../resources/app_colors.dart';
import '../resources/app_metrics.dart';
import '../resources/app_strings.dart';

/// 导入预览里的一行课程。
///
/// 不依赖课表 store：预览阶段课程还没进本地存储，
/// 这里只展示识别/取回拿到的原始字段。
class CoursePreviewTile extends StatelessWidget {
  const CoursePreviewTile({required this.course, super.key});

  final Course course;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppMetrics.sp4,
        vertical: AppMetrics.sp3,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceSunken,
        borderRadius: BorderRadius.circular(AppMetrics.rLg),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Column(
              children: [
                Text(
                  AppStrings.weekLabels[(course.dayOfWeek - 1).clamp(0, 6)],
                  style: const TextStyle(
                    fontSize: AppMetrics.tiny,
                    color: AppColors.ink500,
                  ),
                ),
                Text(
                  AppStrings.lessonRangeText(
                    course.startLesson,
                    course.endLesson,
                  ),
                  style: const TextStyle(
                    fontSize: AppMetrics.tiny,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brand700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppMetrics.sp3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.name.isEmpty ? AppStrings.unnamedCourse : course.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: AppMetrics.body,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    course.location.trim(),
                    course.teacher.trim(),
                    course.weekText,
                  ].where((value) => value.isNotEmpty).join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: AppMetrics.tiny,
                    color: AppColors.ink500,
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
