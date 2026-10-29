import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../models/course.dart';
import '../models/school.dart';
import '../resources/app_colors.dart';
import '../resources/app_metrics.dart';
import '../resources/app_strings.dart';
import '../services/academic_browser.dart';
import '../services/course_reader_script.dart';
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

  Future<void> _readPage() async {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    setState(() => _reading = true);
    try {
      final raw = await controller.evaluateJavascript(
        source: CourseReaderScript.readCourses,
      );
      final text = raw is String ? raw : '';
      final result = AcademicBrowser.interpret(
        text,
        maxWeek: widget.maxWeek,
        schoolName: widget.school.name,
      );
      if (!mounted) {
        return;
      }
      if (result.isEmpty) {
        setState(() => _status = describeReadFailure(text));
      } else {
        _applyCourses(result.courses);
      }
    } catch (_) {
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

  Future<void> _reload() async {
    setState(() {
      _courses = const [];
      _status = '';
    });
    await _controller?.reload();
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
                  initialUrlRequest: widget.school.login.loginUrl.isEmpty
                      ? null
                      : URLRequest(url: WebUri(widget.school.login.loginUrl)),
                  onWebViewCreated: (controller) => _controller = controller,
                  onLoadStart: (controller, url) {
                    setState(() {
                      _loading = true;
                      _address = url?.toString() ?? '';
                    });
                  },
                  onLoadStop: (controller, url) {
                    setState(() {
                      _loading = false;
                      _address = url?.toString() ?? '';
                    });
                  },
                  onProgressChanged: (controller, progress) {
                    setState(() => _progress = progress / 100);
                  },
                  shouldOverrideUrlLoading: (controller, action) async {
                    final uri = action.request.url;
                    if (uri == null) {
                      return NavigationActionPolicy.CANCEL;
                    }
                    // 学校系统常见的 QQ / 微信登录需要外开，
                    // 这里仍留在内置浏览器里，保证登录后能读到课表。
                    return NavigationActionPolicy.ALLOW;
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
