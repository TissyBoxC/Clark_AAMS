import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:share_plus/share_plus.dart';

import '../models/course.dart';
import '../models/school.dart';
import '../resources/app_colors.dart';
import '../resources/app_metrics.dart';
import '../resources/app_strings.dart';
import '../services/academic_browser.dart';
import '../services/course_reader_script.dart';
import '../services/diag_log.dart';
import '../widgets/app_icons.dart';
import '../widgets/soft_ui.dart';
import 'import_preview.dart';

/// 内置浏览器解析课表的页面。
///
/// 用户在这里登录学校教务系统 —— 账号密码直接进学校页面，
/// 应用本身不保存；打开课表那页后点「读取这一页的课表」，
/// 应用就读出课程并交给用户核对。
class AcademicBrowserPage extends StatefulWidget {
  const AcademicBrowserPage({
    required this.school,
    required this.maxWeek,
    super.key,
  });

  final School school;
  final int maxWeek;

  @override
  State<AcademicBrowserPage> createState() => _AcademicBrowserPageState();
}

class _AcademicBrowserPageState extends State<AcademicBrowserPage> {
  InAppWebViewController? _controller;
  double _progress = 0;
  bool _loading = true;
  bool _reading = false;
  String _address = '';
  String _status = '';
  List<Course> _courses = const [];

  void _applyCourses(List<Course> courses) {
    setState(() {
      _courses = courses;
      _status = courses.isEmpty
          ? '还没有读到课表'
          : '读到 ${courses.length} 门课，核对无误就可以存进课表。';
    });
  }

  /// 从 WebView 读回当前真实地址。
  ///
  /// 主文档地址往往只是外壳，课表在内嵌页里。这里先取 `currentUrl`，
  /// 再问一下页面内有没有正在显示课表的 iframe，有就用它的地址——
  /// 否则地址栏显示的仍是首页，用户看到的就是"链接锁在首页"。
  Future<void> _syncAddress(InAppWebViewController controller) async {
    String mainUrl = '';
    try {
      mainUrl = (await controller.getUrl())?.toString() ?? '';
    } catch (error, stack) {
      DiagLog.instance.error('getUrl 失败', error, stack);
      return;
    }
    DiagLog.instance.line('主文档地址: $mainUrl', tag: 'sync');

    // 主文档地址已经有了，再看 iframe。取不到就用主文档地址，不报错。
    String frameUrl = '';
    try {
      final raw = await controller.evaluateJavascript(
        source: CourseReaderScript.currentFrameUrl,
      );
      DiagLog.instance.line('iframe 探测原始返回: $raw', tag: 'sync');
      if (raw is String) {
        frameUrl = raw.trim();
      }
    } catch (error, stack) {
      DiagLog.instance.error('iframe 探测失败', error, stack);
    }

    final address = frameUrl.isNotEmpty ? frameUrl : mainUrl;
    DiagLog.instance.line(
      '采用地址: $address（来源: ${frameUrl.isNotEmpty ? "iframe" : "主文档"}）',
      tag: 'sync',
    );

    if (!mounted || address.isEmpty || address == _address) {
      return;
    }
    setState(() => _address = address);
  }

  /// 抓一份页面结构快照，排查用。
  ///
  /// 课表到底在不在 iframe 里、有几个 iframe、各自哪个域，
  /// 这些光靠猜永远猜不准，直接把它记下来。
  Future<void> _dumpPageStructure(InAppWebViewController controller) async {
    try {
      final raw = await controller.evaluateJavascript(
        source: CourseReaderScript.dumpStructure,
      );
      DiagLog.instance.line('页面结构快照:\n$raw', tag: 'dump');
    } catch (error, stack) {
      DiagLog.instance.error('结构快照失败', error, stack);
    }
  }

  Future<void> _readPage() async {
    final controller = _controller;
    if (controller == null) {
      DiagLog.instance.line('读取课表时 controller 为空', tag: 'read');
      return;
    }
    setState(() => _reading = true);
    try {
      final raw = await controller.evaluateJavascript(
        source: CourseReaderScript.readCourses,
      );
      final text = raw is String ? raw : '';
      // 读取结果原样记下来：读不到时，reason 和 scannedDocs 能直接定位
      DiagLog.instance.line(
        '读取返回（前 500 字）: ${text.length > 500 ? text.substring(0, 500) : text}',
        tag: 'read',
      );
      final result = AcademicBrowser.interpret(
        text,
        maxWeek: widget.maxWeek,
        schoolName: widget.school.name,
      );
      DiagLog.instance.line('解析出 ${result.courses.length} 门课', tag: 'read');
      if (!mounted) {
        return;
      }
      if (result.isEmpty) {
        setState(() => _status = describeReadFailure(text));
      } else {
        _applyCourses(result.courses);
      }
    } catch (error, stack) {
      DiagLog.instance.error('读取课表异常', error, stack);
      if (mounted) {
        setState(() => _status = '这一页读不出来，稍后再试一次。');
      }
    } finally {
      if (mounted) {
        setState(() => _reading = false);
      }
    }
  }

  Future<void> _openScheduleTab() async {
    await _controller?.evaluateJavascript(
      source: CourseReaderScript.openScheduleTab,
    );
  }

  /// 重读当前页。
  ///
  /// 重读当前页。
  ///
  /// 分三步试，一步不成才走下一步：
  ///   1. 让页面自己重载显示课表的那个 iframe —— 外层框架和登录态都保住
  ///   2. 退回 `reload()` —— 只重载主文档，可能回首页，但不会掉登录
  ///   3. 都不用 `loadUrl` 跳到 iframe 地址
  ///
  /// 第 3 步是上一版的做法，它是错的：iframe 的 src 是裸的
  /// `content_xs.aspx`，不带外层参数，直接跳过去教务系统判为无效请求，
  /// 反而把登录弄掉。这条路径现在只在极端情况下才走，且不再优先。
  Future<void> _reload() async {
    DiagLog.instance.line('=== 用户点了刷新 ===', tag: 'reload');
    setState(() {
      _courses = const [];
      _status = '';
    });
    final controller = _controller;
    if (controller == null) {
      DiagLog.instance.line('controller 为空，跳过', tag: 'reload');
      return;
    }

    // 第一步：只重载 iframe，主文档不动
    try {
      final reloaded = await controller.evaluateJavascript(
        source: CourseReaderScript.reloadScheduleFrame,
      );
      DiagLog.instance.line('重载 iframe 结果: $reloaded', tag: 'reload');
      if (reloaded == 'reloaded') {
        await _syncAddress(controller);
        return;
      }
    } catch (error, stack) {
      DiagLog.instance.error('重载 iframe 失败', error, stack);
    }

    // 第二步：整页重载。只影响主文档，不会把登录弄掉
    DiagLog.instance.line('退回整页 reload()', tag: 'reload');
    await controller.reload();
  }

  /// 导出诊断日志。
  ///
  /// 导出前先补抓一次当前页面结构和地址——用户点这个按钮的时刻，
  /// 正好是"界面已经跳到课表了"的那一刻，这份现场比任何历史记录都值钱。
  Future<void> _exportLog() async {
    final controller = _controller;
    if (controller != null) {
      DiagLog.instance.line('=== 用户导出日志，抓取现场 ===', tag: 'export');
      await _syncAddress(controller);
      await _dumpPageStructure(controller);
      try {
        final current = await controller.getUrl();
        DiagLog.instance.line('导出时 getUrl = $current', tag: 'export');
      } catch (error, stack) {
        DiagLog.instance.error('导出时 getUrl 失败', error, stack);
      }
    }

    await DiagLog.instance.flush();
    final content = await DiagLog.instance.readAll();

    if (!mounted) {
      return;
    }
    // 对话框关掉之后要用页面自己的 context 弹提示，先取出来
    final messenger = ScaffoldMessenger.of(context);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('诊断日志'),
        content: SizedBox(
          width: double.maxFinite,
          height: 320,
          child: SingleChildScrollView(
            child: SelectableText(
              content,
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: content));
              // 复制是异步的，回来之后对话框可能已经没了，先确认还在
              if (!dialogContext.mounted) {
                return;
              }
              Navigator.of(dialogContext).pop();
              messenger.showSnackBar(
                const SnackBar(content: Text('已复制，粘贴发给我就行')),
              );
            },
            child: const Text('复制全文'),
          ),
          TextButton(
            onPressed: () async {
              final path = DiagLog.instance.filePath;
              if (path == null) {
                return;
              }
              await SharePlus.instance.share(
                ShareParams(
                  files: [XFile(path)],
                  text: '珂拉课程表诊断日志',
                ),
              );
            },
            child: const Text('分享文件'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Future<void> _finish() async {
    if (_courses.isEmpty) {
      return;
    }
    Navigator.of(context).pop(_courses);
  }

  @override
  Widget build(BuildContext context) {
    if (!AcademicBrowser.isSupported) {
      return _UnsupportedView(school: widget.school);
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(widget.school.name),
        leading: IconButton(
          icon: const Icon(AppIcons.close),
          tooltip: AppStrings.close,
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: '导出诊断日志',
            icon: const Icon(AppIcons.copy),
            onPressed: _exportLog,
          ),
          IconButton(
            tooltip: '重新载入这一页',
            icon: const Icon(AppIcons.refresh),
            onPressed: _reload,
          ),
        ],
        bottom: _progress > 0 && _progress < 1
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 2,
                  backgroundColor: AppColors.surfaceSunken,
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          _Toolbar(
            address: _address,
            status: _status,
            reading: _reading,
            onRead: _readPage,
            onOpenSchedule: _openScheduleTab,
          ),
          if (_courses.isNotEmpty)
            _PreviewStrip(courses: _courses, onSave: _finish),
          Expanded(
            child: Stack(
              children: [
                InAppWebView(
                  /*
                   * 让 WebView 把 cookie 存到磁盘。
                   * 默认是内存态，退出这一页教务系统的登录就没了，
                   * 下次进还得重新登录。学校系统靠 cookie 认人，
                   * 存住它，重开时多半还能直接停在已登录状态。
                   */
                  initialSettings: InAppWebViewSettings(
                    thirdPartyCookiesEnabled: true,
                    sharedCookiesEnabled: true,
                    cacheEnabled: true,
                    javaScriptEnabled: true,
                    domStorageEnabled: true,
                    databaseEnabled: true,
                    clearCache: false,
                  ),
                  initialUrlRequest: widget.school.login.loginUrl.isEmpty
                      ? null
                      : URLRequest(url: WebUri(widget.school.login.loginUrl)),
                  onWebViewCreated: (controller) {
                    _controller = controller;
                    DiagLog.instance.line('WebView 已创建', tag: 'webview');
                  },
                  onLoadStart: (controller, url) {
                    DiagLog.instance.line('onLoadStart: $url', tag: 'webview');
                    setState(() {
                      _loading = true;
                      _address = url?.toString() ?? '';
                    });
                  },
                  onLoadStop: (controller, url) async {
                    DiagLog.instance.line('onLoadStop: $url', tag: 'webview');
                    setState(() {
                      _loading = false;
                      _address = url?.toString() ?? '';
                    });
                    // 有的页面加载完才做跳转，这里补读一次真实地址
                    await _syncAddress(controller);
                    await _dumpPageStructure(controller);
                  },
                  /*
                   * 教务系统的课表切换多半发生在 iframe 里：地址栏不动，
                   * 只换 iframe 的 src。此时 onLoadStart/onLoadStop 都不会触发，
                   * 于是界面已经变了、记录下来的地址还停在首页，
                   * 刷新又跳回去。这个回调在 iframe 导航和历史变更时也会来，
                   * 用它把地址同步上。
                   */
                  onUpdateVisitedHistory: (controller, url, isReload) async {
                    DiagLog.instance.line(
                      'onUpdateVisitedHistory: url=$url isReload=$isReload',
                      tag: 'webview',
                    );
                    await _syncAddress(controller);
                  },
                  onProgressChanged: (controller, progress) {
                    setState(() => _progress = progress / 100);
                  },
                  shouldOverrideUrlLoading: (controller, action) async {
                    final uri = action.request.url;
                    DiagLog.instance.line(
                      'shouldOverrideUrlLoading: $uri '
                      '(isForMainFrame=${action.isForMainFrame})',
                      tag: 'webview',
                    );
                    if (uri == null) {
                      return NavigationActionPolicy.CANCEL;
                    }
                    // 学校系统常见的 QQ / 微信登录需要外开，
                    // 这里仍留在内置浏览器里，保证登录后能读到课表。
                    return NavigationActionPolicy.ALLOW;
                  },
                  onReceivedHttpError: (controller, request, response) {
                    DiagLog.instance.line(
                      'onReceivedHttpError: ${request.url} -> ${response.statusCode}',
                      tag: 'webview',
                    );
                  },
                  onConsoleMessage: (controller, message) {
                    DiagLog.instance.line(
                      'console[${message.messageLevel}]: ${message.message}',
                      tag: 'js',
                    );
                  },
                ),
                if (_loading)
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.address,
    required this.status,
    required this.reading,
    required this.onRead,
    required this.onOpenSchedule,
  });

  final String address;
  final String status;
  final bool reading;
  final VoidCallback onRead;
  final VoidCallback onOpenSchedule;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppMetrics.sp4,
        AppMetrics.sp3,
        AppMetrics.sp4,
        AppMetrics.sp3,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(AppIcons.school, size: 18, color: AppColors.ink400),
              const SizedBox(width: AppMetrics.sp2),
              Expanded(
                child: Text(
                  address.isEmpty ? '正在打开学校页面' : address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: AppMetrics.tiny,
                    color: AppColors.ink500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppMetrics.sp2),
          Row(
            children: [
              QuietButton(
                label: '去课表页面',
                icon: AppIcons.schedule,
                onPressed: onOpenSchedule,
              ),
              const SizedBox(width: AppMetrics.sp2),
              PrimaryButton(
                label: reading ? '正在读取' : '读取这一页的课表',
                icon: AppIcons.download,
                loading: reading,
                onPressed: onRead,
              ),
            ],
          ),
          if (status.isNotEmpty) ...[
            const SizedBox(height: AppMetrics.sp2),
            Text(
              status,
              style: const TextStyle(
                fontSize: AppMetrics.tiny,
                color: AppColors.ink600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PreviewStrip extends StatelessWidget {
  const _PreviewStrip({required this.courses, required this.onSave});

  final List<Course> courses;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.brand050,
      padding: const EdgeInsets.fromLTRB(
        AppMetrics.sp4,
        AppMetrics.sp3,
        AppMetrics.sp4,
        AppMetrics.sp3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '读到 ${courses.length} 门课',
                  style: const TextStyle(
                    fontSize: AppMetrics.small,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brand700,
                  ),
                ),
              ),
              PrimaryButton(label: '存进课表', onPressed: onSave),
            ],
          ),
          const SizedBox(height: AppMetrics.sp2),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: courses.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppMetrics.sp2),
              itemBuilder: (context, index) =>
                  CoursePreviewTile(course: courses[index]),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnsupportedView extends StatelessWidget {
  const _UnsupportedView({required this.school});

  final School school;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(school.name),
        leading: IconButton(
          icon: const Icon(AppIcons.close),
          tooltip: AppStrings.close,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppMetrics.sp5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(AppIcons.alert, size: 32, color: AppColors.ink400),
              const SizedBox(height: AppMetrics.sp3),
              Text(
                Platform.isLinux
                    ? '这台电脑上暂时打不开学校页面，请改用截图识别导入课表。'
                    : '这里打不开学校页面，请改用截图识别导入课表。',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: AppMetrics.body,
                  height: 1.7,
                  color: AppColors.ink600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
