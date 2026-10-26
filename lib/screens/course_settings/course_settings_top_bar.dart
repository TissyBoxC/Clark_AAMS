import 'package:flutter/material.dart';

import '../../resources/app_strings.dart';
import '../../widgets/top_bar.dart';

/// 课程设置页顶栏。
///
/// 原本内联在 `_CourseSettingsPageState.build()` 里（约 50 行），
/// 与课表列表、批量删除栏、悬浮按钮挤在同一个方法中。
///
/// 抽出来的理由：这是纯 UI，只通过回调与页面通信，
/// 因此可以脱离页面状态单独测试，尤其是「批量删除模式下隐藏菜单」
/// 这种以前必须起整页才能验证的分支。
class CourseSettingsTopBar extends StatelessWidget {
  const CourseSettingsTopBar({
    super.key,
    required this.batchDeleteMode,
    required this.onBack,
    required this.onImport,
    required this.onBatchAdd,
    required this.onBatchDelete,
  });

  /// 批量删除模式：此时隐藏更多菜单。
  ///
  /// 必须隐藏——该模式下页面处于「已选中若干项、等待确认删除」的状态，
  /// 再允许打开导入会让人以为两者可以并行，
  /// 而实际点「确认删除」时导入结果会被覆盖。
  final bool batchDeleteMode;

  final VoidCallback onBack;
  final VoidCallback onImport;
  final VoidCallback onBatchAdd;
  final VoidCallback onBatchDelete;

  @override
  Widget build(BuildContext context) {
    return TopBar(
      title: AppStrings.courseSettingsTitle,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onBack,
      ),
      trailing: batchDeleteMode
          ? const SizedBox(width: 48)
          : PopupMenuButton<CourseSettingsMenuAction>(
              icon: const Icon(Icons.more_horiz, color: Color(0xff6b4f5a)),
              onSelected: (value) {
                switch (value) {
                  case CourseSettingsMenuAction.importSchedule:
                    onImport();
                  case CourseSettingsMenuAction.batchAdd:
                    onBatchAdd();
                  case CourseSettingsMenuAction.batchDelete:
                    onBatchDelete();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: CourseSettingsMenuAction.importSchedule,
                  child: Text(AppStrings.importCourses),
                ),
                PopupMenuItem(
                  value: CourseSettingsMenuAction.batchAdd,
                  child: Text(AppStrings.batchAdd),
                ),
                PopupMenuItem(
                  value: CourseSettingsMenuAction.batchDelete,
                  child: Text(AppStrings.batchDelete),
                ),
              ],
            ),
    );
  }
}

/// 顶栏更多菜单的动作。
enum CourseSettingsMenuAction {
  importSchedule,
  batchAdd,
  batchDelete,
}
