import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/course.dart';
import '../models/school.dart';
import '../services/clark_backend_api.dart';

class AcademicImportPage extends StatefulWidget {
  const AcademicImportPage({super.key, required this.school});

  final School school;

  @override
  State<AcademicImportPage> createState() => _AcademicImportPageState();
}

class _AcademicImportPageState extends State<AcademicImportPage> {
  late final WebViewController _controller;
  late final WebViewCookieManager _cookieManager;

  bool _loading = true;
  bool _importing = false;
  String _status = '请在页面中登录教务系统';

  @override
  void initState() {
    super.initState();
    _cookieManager = WebViewCookieManager();

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
      ..loadRequest(Uri.parse(widget.school.login.loginUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.school.shortName} 教务导入'),
        actions: [
          IconButton(
            tooltip: '重新加载',
            onPressed: _importing
                ? null
                : () => _controller.loadRequest(
                    Uri.parse(widget.school.login.loginUrl),
                  ),
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
            child: _ImportStatusBar(message: _status, busy: _importing),
          ),
          if (_loading || _importing)
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
    if (_importing || !_matchesSuccessUrl(url)) {
      return;
    }

    setState(() {
      _importing = true;
      _status = '检测到登录成功，正在提交后端导入';
    });

    try {
      final cookie = await _readCookies();
      if (cookie.isEmpty) {
        throw const ApiException(40101, '未读取到登录 Cookie，请重新登录');
      }
      final studentId = await _extractStudentId(url);
      final courses = await ClarkBackendApi.instance.importCourses(
        schoolId: widget.school.id,
        cookie: cookie,
        studentId: studentId,
        successUrl: url,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop<List<Course>>(courses);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _status = '导入失败：$error';
        _importing = false;
      });
    }
  }

  bool _matchesSuccessUrl(String url) {
    final patterns = widget.school.login.successUrlPatterns;
    if (patterns.isEmpty) {
      return false;
    }
    return patterns.any((pattern) => _wildcardMatch(pattern, url));
  }

  bool _wildcardMatch(String pattern, String value) {
    final escaped = RegExp.escape(pattern).replaceAll(r'\*', '.*');
    return RegExp('^$escaped\$').hasMatch(value);
  }

  Future<String> _readCookies() async {
    final cookiePairs = <String>{};
    final urls = <Uri>[];

    final currentUrl = await _controller.currentUrl();
    if (currentUrl != null) {
      final parsed = Uri.tryParse(currentUrl);
      if (parsed != null) {
        urls.add(parsed);
      }
    }

    final loginUrl = Uri.tryParse(widget.school.login.loginUrl);
    if (loginUrl != null) {
      urls.add(loginUrl);
    }

    for (final uri in urls) {
      try {
        final cookies = await _cookieManager.platform.getCookies(uri);
        for (final cookie in cookies) {
          if (cookie.name.isNotEmpty && cookie.value.isNotEmpty) {
            cookiePairs.add('${cookie.name}=${cookie.value}');
          }
        }
      } catch (_) {
        // Ignore platform cookie retrieval failures and fall back to JS.
      }
    }

    if (cookiePairs.isNotEmpty) {
      return cookiePairs.join('; ');
    }

    final result = await _controller.runJavaScriptReturningResult(
      'document.cookie',
    );
    return _decodeJavaScriptString(result);
  }

  Future<String> _extractStudentId(String url) async {
    final uri = Uri.tryParse(url);
    final fromUrl =
        uri?.queryParameters['xh'] ??
        uri?.queryParameters['studentId'] ??
        uri?.queryParameters['student_id'];
    if (fromUrl != null && fromUrl.trim().isNotEmpty) {
      return fromUrl.trim();
    }

    final result = await _controller.runJavaScriptReturningResult('''
(() => {
  const selectors = [
    'input[name="xh"]',
    'input[name="studentId"]',
    'input[name="student_id"]',
    '#xh',
    '#studentId'
  ];
  for (const selector of selectors) {
    const node = document.querySelector(selector);
    if (!node) continue;
    const value = node.value || node.textContent || '';
    if (value.trim()) return value.trim();
  }
  const match = document.body.innerText.match(/\\b\\d{6,20}\\b/);
  return match ? match[0] : '';
})()
''');
    return _decodeJavaScriptString(result);
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
