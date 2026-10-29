import 'package:flutter/material.dart';

import '../models/course.dart';
import '../resources/app_colors.dart';
import '../resources/app_metrics.dart';
import '../resources/app_strings.dart';
import '../services/schedule_scope.dart';
import '../services/schedule_utils.dart';

/// 单门课程卡片：左侧色条 + 名称 + 时间地点。
///
/// 课表、今日课程、导入预览都用它，保证同一门课在三个地方长得一样。
class CourseTile extends StatelessWidget {
  const CourseTile({
    required this.course,
    this.onTap,
    this.trailing,
    this.showWeek = true,
    super.key,
  });

  final Course course;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showWeek;

  @override
  Widget build(BuildContext context) {
    final tone = AppColors.courseTone(_toneIndex(course.name));
    final settings = ScheduleScope.of(context).settings;
    final time = ScheduleUtils.timeRange(settings, course);
    final meta = [
      AppStrings.fullWeekdays[(course.dayOfWeek - 1).clamp(0, 6)],
      AppStrings.lessonRangeText(course.startLesson, course.endLesson),
      if (time.isNotEmpty) time,
      if (course.location.trim().isNotEmpty) course.location.trim(),
    ].join(' · ');

    return Material(
      color: AppColors.surfaceSunken,
      borderRadius: BorderRadius.circular(AppMetrics.rLg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppMetrics.sp4,
            vertical: AppMetrics.sp3,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 40,
                margin: const EdgeInsets.only(right: AppMetrics.sp3, top: 2),
                decoration: BoxDecoration(
                  color: tone[1],
                  borderRadius: BorderRadius.circular(AppMetrics.rPill),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: AppMetrics.body,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      meta,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: AppMetrics.tiny,
                        height: 1.5,
                        color: AppColors.ink500,
                      ),
                    ),
                    if (showWeek) ...[
                      const SizedBox(height: 4),
                      Text(
                        course.weekText,
                        style: const TextStyle(
                          fontSize: AppMetrics.tiny,
                          color: AppColors.ink400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppMetrics.sp2),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 用课程名算一个稳定的色号，同一门课换设备也是同一个颜色。
  static int _toneIndex(String name) {
    if (name.isEmpty) {
      return 0;
    }
    return name.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
  }
}
