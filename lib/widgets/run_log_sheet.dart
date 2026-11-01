import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../resources/app_metrics.dart';
import '../resources/app_strings.dart';
import '../services/diag_log.dart';

/// 运行记录的查看与导出。
///
/// 出问题时用户点一下就能把记录发出来，不用教他怎么找文件。
/// 这里只管展示和带走，记录内容由 [DiagLog] 写。
class RunLogSheet {
  const RunLogSheet._();

  /// 弹出运行记录。
  ///
  /// [extra] 用来在导出前补抓现场（比如当前页面结构）。
  /// 传进来的内容会先写进日志，再展示——用户看到的和发出去的是同一份。
  static Future<void> show(
    BuildContext context, {
    Future<void> Function()? captureBefore,
  }) async {
    if (captureBefore != null) {
      try {
        await captureBefore();
      } catch (_) {
        // 补抓失败不影响展示已有记录
      }
    }

    await DiagLog.instance.flush();
    final content = await DiagLog.instance.readAll();
    if (!context.mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('运行记录'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              AppStrings.runLogHint,
              style: TextStyle(fontSize: AppMetrics.small),
            ),
            const SizedBox(height: AppMetrics.sp3),
            SizedBox(
              width: double.maxFinite,
              height: 280,
              child: SingleChildScrollView(
                child: SelectableText(
                  content,
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: content));
              // 复制是异步的，回来时对话框可能已经没了
              if (!dialogContext.mounted) {
                return;
              }
              Navigator.of(dialogContext).pop();
              messenger.showSnackBar(const SnackBar(content: Text('已复制')));
            },
            child: const Text('复制'),
          ),
          TextButton(
            onPressed: () async {
              final path = DiagLog.instance.filePath;
              if (path == null) {
                return;
              }
              await SharePlus.instance.share(
                ShareParams(files: [XFile(path)], text: AppStrings.runLogShareText),
              );
            },
            child: const Text('发送文件'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(AppStrings.close),
          ),
        ],
      ),
    );
  }
}
