/// 课程设置页的纯判定与提示逻辑。
///
/// 这些函数原本是 `_CourseSettingsPageState` 的私有方法，混在 683 行的
/// 状态类里。抽出来的理由不是「行数好看」，而是它们**只依赖入参、不依赖页面状态**。
///
/// 留在 State 里时，要测它们只能起一个完整页面、模拟点击；
/// 抽成纯函数后可以直覆盖边界——而这里恰好有真实的判断风险：
/// 学校声明支持教务导入、登录模式也对，但 `loginUrl` 为空时，
/// 用户点进去会看到一片白屏。这个组合以前没有任何测试。
library;

import '../../models/school.dart';

/// 该校是否真的能用教务系统导入。
///
/// 三个条件缺一不可：
///
/// 1. 学校声明支持
/// 2. 登录方式是 webview（其余方式没有可注入的页面）
/// 3. 登录地址非空 —— 声明支持但地址为空是数据配置错误，
///    放行会让 WebView 加载空白页，用户只看到白屏且无从判断原因
bool canUseAcademicImport(School school) {
  return school.supportsAcademicImport &&
      school.login.mode == 'webview' &&
      school.login.loginUrl.isNotEmpty;
}

/// 归一「当前不可用」的提示文案。
///
/// 空串或纯空白会被替换成通用提示：
/// 空 SnackBar 等于什么都没发生，用户会以为按钮坏了。
String unavailableMessage(String message) {
  final trimmed = message.trim();
  if (trimmed.isEmpty) {
    return '该功能当前不可用，请稍后再试';
  }
  return message;
}

/// 阻塞式提示（不可关闭）的展示内容。
///
/// 识别、导入这类操作可能持续数秒，期间必须挡住交互，
/// 且**不能**提供关闭按钮——提前关掉会导致后续回调写进已销毁的页面。
class BlockingBody {
  const BlockingBody({required this.message, required this.showProgress});

  final String message;
  final bool showProgress;
}

/// 构造阻塞提示内容。
BlockingBody blockingBody(String message) {
  return BlockingBody(message: message, showProgress: true);
}
