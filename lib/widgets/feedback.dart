import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../resources/app_colors.dart';
import '../resources/app_metrics.dart';
import '../resources/app_strings.dart';
import 'soft_ui.dart';

/// 全站提示：底部浮起一条，4 秒后自动收起。
///
/// 统一入口，避免各页面各写一套 SnackBar；
/// 文案规范是「说清结果」，不写「操作成功」这种空话。
class AppNotice {
  const AppNotice._();

  static void show(
    BuildContext context,
    String message, {
    NoticeTone tone = NoticeTone.info,
    SnackBarAction? action,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          action: action,
          content: Row(
            children: [
              Icon(
                switch (tone) {
                  NoticeTone.success => Icons.check_circle_outline,
                  NoticeTone.error => Icons.error_outline,
                  NoticeTone.warn => Icons.warning_amber_outlined,
                  NoticeTone.info => Icons.info_outline,
                },
                size: 18,
                color: AppColors.inkInverse,
              ),
              const SizedBox(width: AppMetrics.sp3),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }

  static void success(BuildContext context, String message) =>
      show(context, message, tone: NoticeTone.success);

  static void error(BuildContext context, String message) =>
      show(context, message, tone: NoticeTone.error);
}

/// 写死的一段说明文字，用于「设成怎样都行，但要让人看懂」的位置。
class HintText extends StatelessWidget {
  const HintText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: AppMetrics.small,
        height: 1.7,
        color: AppColors.ink500,
      ),
    );
  }
}

/// 危险操作的确认对话框：先说后果，再让人决定。
Future<bool> confirmDanger(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = AppStrings.cancel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.danger600,
            foregroundColor: AppColors.inkInverse,
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// 把文本写进剪贴板，并回一条提示。
Future<void> copyWithNotice(BuildContext context, String value) async {
  await Clipboard.setData(ClipboardData(text: value));
  if (context.mounted) {
    AppNotice.success(context, AppStrings.copiedToClipboard);
  }
}

/// 把时间字符串（HH:mm）解析成一天中的分钟数。
int? minutesOfDay(String raw) {
  final normalized = raw.trim().replaceAll('：', ':');
  final parts = normalized.split(':');
  if (parts.length != 2) {
    return null;
  }
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) {
    return null;
  }
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
    return null;
  }
  return hour * 60 + minute;
}

/// 分钟数转回 HH:mm。
String formatMinutes(int minutes) {
  final normalized = minutes.clamp(0, 24 * 60);
  final hour = (normalized ~/ 60).toString().padLeft(2, '0');
  final minute = (normalized % 60).toString().padLeft(2, '0');
  return '$hour:$minute';
}
