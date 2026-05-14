import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'jit_course_importer.dart';
import 'jit_jwxt_parser.dart';

class JitAcademicImportPage extends StatefulWidget {
  const JitAcademicImportPage({super.key});

  @override
  State<JitAcademicImportPage> createState() => _JitAcademicImportPageState();
}

class _JitAcademicImportPageState extends State<JitAcademicImportPage> {
  late final WebViewController _controller;

  bool _loading = true;
  bool _parsing = false;
  String _status = '请在浏览器页面中手动登录教务系统';

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => _setLoading(true),
          onPageFinished: (url) async {
            _setLoading(false);
            await _handlePossibleLogin(url);
          },
          onWebResourceError: (error) {
            if (!mounted || error.isForMainFrame != true) {
              return;
            }
            setState(() {
              _loading = false;
              _status = '页面加载失败，请检查网络后重试';
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(JitJwxtParser.loginUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('金陵科技学院教务导入'),
        actions: [
          IconButton(
            tooltip: '重新加载',
            onPressed: () {
              _controller.loadRequest(Uri.parse(JitJwxtParser.loginUrl));
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _ImportStatusBar(message: _status, busy: _parsing),
          ),
          if (_loading || _parsing)
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: LinearProgressIndicator(minHeight: 2),
            ),
        ],
      ),
    );
  }

  void _setLoading(bool value) {
    if (!mounted) {
      return;
    }
    setState(() => _loading = value);
  }

  Future<void> _handlePossibleLogin(String url) async {
    if (_parsing || !_looksLikeLoginSuccess(url)) {
      return;
    }

    setState(() {
      _parsing = true;
      _status = '检测到登录成功，正在查找课表 Table6';
    });

    try {
      final html = await _getIndexChartsHtml();
      final rawCourses = JitJwxtParser.parseIndexChartsTable(html);
      final courses = JitCourseImporter.parseRawCourses(rawCourses);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(courses);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _status = '未找到课表，请进入学生主页或稍后重试：$error';
        _parsing = false;
      });
    }
  }

  bool _looksLikeLoginSuccess(String url) {
    return url.contains('xs_main.aspx') ||
        url.contains('framework') ||
        url.contains('main') ||
        url.contains('content_xs.aspx');
  }

  Future<String> _getIndexChartsHtml() async {
    await Future<void>.delayed(const Duration(seconds: 3));

    final pageHtml = await _pageHtml();
    if (JitJwxtParser.pageHasTable6(pageHtml)) {
      return pageHtml;
    }

    final targetFrameHtml = await _frameHtml(targetOnly: true);
    if (targetFrameHtml != null &&
        JitJwxtParser.pageHasTable6(targetFrameHtml)) {
      return targetFrameHtml;
    }

    final tableFrameHtml = await _frameHtml(
      targetOnly: false,
      requireTable6: true,
    );
    if (tableFrameHtml != null) {
      return tableFrameHtml;
    }

    throw const FormatException('未找到 table#Table6');
  }

  Future<String> _pageHtml() async {
    final result = await _controller.runJavaScriptReturningResult(
      'document.documentElement.outerHTML',
    );
    return _decodeJavaScriptString(result);
  }

  Future<String?> _frameHtml({
    required bool targetOnly,
    bool requireTable6 = false,
  }) async {
    final script =
        '''
(() => {
  const isTarget = (frame) => {
    const name = frame.getAttribute('name') || '';
    const id = frame.getAttribute('id') || '';
    const src = frame.getAttribute('src') || '';
    return name === 'zhutii' ||
      id === 'iframeautoheight' ||
      src.includes('content_xs.aspx');
  };
  const search = (doc, onlyTarget, requireTable) => {
    const frames = Array.from(doc.querySelectorAll('iframe'));
    for (const frame of frames) {
      if (onlyTarget && !isTarget(frame)) continue;
      try {
        const childDoc = frame.contentDocument || frame.contentWindow.document;
        const html = childDoc.documentElement.outerHTML;
        if (!requireTable || childDoc.querySelector('table#Table6')) return html;
        const nested = search(childDoc, false, requireTable);
        if (nested) return nested;
      } catch (_) {}
    }
    return '';
  };
  return search(document, ${targetOnly ? 'true' : 'false'}, ${requireTable6 ? 'true' : 'false'});
})()
''';
    final result = await _controller.runJavaScriptReturningResult(script);
    final html = _decodeJavaScriptString(result);
    return html.isEmpty ? null : html;
  }

  String _decodeJavaScriptString(Object? value) {
    if (value == null) {
      return '';
    }
    final text = value.toString();
    if (text == 'null' || text == 'undefined') {
      return '';
    }
    try {
      final decoded = jsonDecode(text);
      if (decoded is String) {
        return decoded;
      }
    } catch (_) {
      // Some platforms already return the raw JavaScript string.
    }
    return text;
  }
}

class _ImportStatusBar extends StatelessWidget {
  const _ImportStatusBar({required this.message, required this.busy});

  final String message;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Material(
        elevation: 8,
        color: colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              if (busy)
                const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(Icons.login, size: 18, color: colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
