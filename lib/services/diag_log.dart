import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// 诊断日志：把运行过程中发生的事按顺序记下来，供排查用。
///
/// 只在 debug 排查版里启用。设计上刻意"什么都记"——按猜的结论去筛日志，
/// 正是之前反复修不好的原因；宁可文件大一点，让事实自己说话。
///
/// 写入策略：内存缓冲 + 定期落盘。WebView 回调很密，
/// 每条都同步写文件会拖慢页面；但崩溃时又要尽量保留已有的内容，
/// 所以每写够一批就立刻 flush。
class DiagLog {
  DiagLog._();

  static final DiagLog instance = DiagLog._();

  static const String _fileName = 'clark-diag.log';
  static const int _flushThreshold = 20;

  final List<String> _buffer = [];
  final Stopwatch _clock = Stopwatch()..start();
  IOSink? _sink;
  File? _file;
  bool _enabled = false;
  int _dropped = 0;

  /// 日志文件路径；还没初始化或初始化失败时为 null。
  String? get filePath => _file?.path;

  bool get enabled => _enabled;

  /// 打开日志。失败不抛异常——日志本身不该把应用搞崩。
  Future<void> start() async {
    if (_enabled) {
      return;
    }
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_fileName');
      _file = file;
      _sink = file.openWrite(mode: FileMode.write);
      _enabled = true;
      line('========================================');
      line('ClarK AAMS 诊断日志');
      line('启动时间: ${DateTime.now().toIso8601String()}');
      line('平台: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}');
      line('========================================');
      await flush();
    } catch (error) {
      // 拿不到可写目录时退化成只打印
      debugPrint('[diag] 日志文件初始化失败: $error');
    }
  }

  /// 记一行。`tag` 用来分组，`message` 是内容。
  void line(String message, {String tag = 'app'}) {
    final stamp = _clock.elapsedMilliseconds.toString().padLeft(7);
    final text = '[$stamp ms][$tag] $message';
    _buffer.add(text);
    if (kDebugMode) {
      debugPrint(text);
    }
    if (_buffer.length >= _flushThreshold) {
      // 不 await：调用点多为同步回调，不能阻塞页面
      unawaited(flush());
    }
  }

  /// 记一个异常，带堆栈。
  void error(String message, Object exception, [StackTrace? stack]) {
    line('$message | 异常: $exception', tag: 'error');
    if (stack != null) {
      for (final row in stack.toString().split('\n').take(12)) {
        line('    $row', tag: 'error');
      }
    }
  }

  /// 把缓冲写进文件。
  Future<void> flush() async {
    final sink = _sink;
    if (sink == null || _buffer.isEmpty) {
      return;
    }
    final pending = List<String>.from(_buffer);
    _buffer.clear();
    try {
      for (final row in pending) {
        sink.writeln(row);
      }
      await sink.flush();
    } catch (error) {
      if (_dropped < 5) {
        debugPrint('[diag] 写日志失败: $error');
        _dropped++;
      }
    }
  }

  /// 读出当前全部日志内容（含未落盘的部分）。
  Future<String> readAll() async {
    await flush();
    final file = _file;
    if (file == null) {
      return _buffer.join('\n');
    }
    try {
      return await file.readAsString();
    } catch (error) {
      return '读取日志失败: $error\n\n${_buffer.join('\n')}';
    }
  }

  /// 清空日志文件，开始新的一次记录。
  Future<void> clear() async {
    _buffer.clear();
    final file = _file;
    if (file == null) {
      return;
    }
    try {
      await _sink?.close();
      _sink = file.openWrite(mode: FileMode.write);
    } catch (error) {
      debugPrint('[diag] 清空日志失败: $error');
    }
  }
}
