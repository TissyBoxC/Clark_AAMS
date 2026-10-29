import 'dart:convert';
import 'dart:io';

import '../models/course.dart';
import '../models/school.dart';
import 'course_reader_script.dart';

/// 内置浏览器读到的原始课程条目。
class ReadCourse {
  const ReadCourse({
    required this.name,
    required this.dayOfWeek,
    required this.startLesson,
    required this.endLesson,
    required this.location,
    required this.rawText,
  });

  final String name;
  final int dayOfWeek;
  final int startLesson;
  final int endLesson;
  final String location;
  final String rawText;
}

/// 教务导入的读取结果。
class AcademicReadResult {
  const AcademicReadResult({
    required this.courses,
    required this.title,
    required this.message,
  });

  final List<Course> courses;
  final String title;
  final String message;

  bool get isEmpty => courses.isEmpty;
}

/// 内置浏览器：打开学校教务系统，登录后读取课表。
///
/// 只做「把页面读成课程」这一件事：打开登录页、等用户登录、
/// 进入课表、执行读取规则、整理成课程。界面在别处。
class AcademicBrowser {
  const AcademicBrowser._();

  /// 当前平台是否内置了浏览器内核。
  static bool get isSupported {
    if (Platform.isAndroid || Platform.isIOS) {
      return true;
    }
    if (Platform.isWindows) {
      return true;
    }
    if (Platform.isMacOS) {
      return true;
    }
    return false;
  }

  /// 桌面端的内核说明：Windows 与 macOS 都走系统自带的浏览器内核，
  /// 不需要另外下载体积很大的运行时。
  static String get engineHint {
    if (Platform.isWindows) {
      return '电脑上使用 Windows 自带的浏览器内核打开学校页面。';
    }
    if (Platform.isMacOS) {
      return '使用 macOS 自带的浏览器内核打开学校页面。';
    }
    return '使用手机自带的浏览器内核打开学校页面。';
  }

  static bool hasLoginPage(School school) => school.login.loginUrl.isNotEmpty;

  static bool hasDedicatedRule(School school) =>
      CourseReaderScript.ruleFor(school.id) != null;

  /// 把读取脚本回传的文字整理成课程。
  static AcademicReadResult interpret(
    String rawJson, {
    required int maxWeek,
    required String schoolName,
  }) {
    final raw = CourseReaderScript.normalize(rawJson);
    if (raw.isEmpty) {
      return AcademicReadResult(
        courses: const <Course>[],
        title: schoolName,
        message: '页面里还没有课表。登录后进入「我的课表」，再读一次。',
      );
    }

    final read = <ReadCourse>[];
    for (final item in raw) {
      final parsed = _parseLesson(item);
      if (parsed != null) {
        read.add(parsed);
      }
    }

    if (read.isEmpty) {
      return AcademicReadResult(
        courses: const <Course>[],
        title: schoolName,
        message: '读到的内容还不是课表。请在页面里打开课表那一页，再读一次。',
      );
    }

    return AcademicReadResult(
      courses: toCourses(read, maxWeek: maxWeek, startId: 1),
      title: schoolName,
      message: '读到 ${read.length} 门课，核对无误就可以存进课表。',
    );
  }

  /// 单条解析：把一格文字拆成课程名、地点与节次。
  static ReadCourse? _parseLesson(Map<String, Object?> item) {
    final text = (item['text'] as String? ?? '').trim();
    if (text.isEmpty) {
      return null;
    }

    final dayIndex = _asInt(item['dayIndex']) ?? -1;
    final span = _asInt(item['span']) ?? 1;
    final rowIndex = _asInt(item['rowIndex']) ?? 0;

    final headText = (item['headText'] as String? ?? '').trim();
    final startLesson = _leadingNumber(headText) ?? (rowIndex + 1).clamp(1, 20);
    final endLesson = (startLesson + span - 1).clamp(startLesson, 20);

    final lines = text
        .split(RegExp(r'[\r\n]+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.isEmpty) {
      return null;
    }

    final name = lines.first.length > 40
        ? lines.first.substring(0, 40)
        : lines.first;
    final rest = lines.skip(1).join(' ');
    final location = _extractLocation(rest);

    return ReadCourse(
      name: name,
      dayOfWeek: (dayIndex + 1).clamp(1, 7),
      startLesson: startLesson,
      endLesson: endLesson,
      location: location,
      rawText: text,
    );
  }

  /// 从剩余文字里挑出教室：优先「楼名 + 房间号」的写法。
  static String _extractLocation(String text) {
    if (text.isEmpty) {
      return '';
    }
    final match = RegExp(
      r'[\u4e00-\u9fa5A-Za-z]{1,8}\s*[A-Z]?\d{2,4}\s*室?',
    ).firstMatch(text);
    if (match != null) {
      return match.group(0)!.trim();
    }
    final tagged = RegExp(r'[@＠]\s*(\S{1,20})').firstMatch(text);
    return tagged?.group(1)?.trim() ?? '';
  }

  static int? _leadingNumber(String text) {
    final match = RegExp(r'\d{1,2}').firstMatch(text);
    if (match == null) {
      return null;
    }
    return int.tryParse(match.group(0)!);
  }

  static int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }
}

/// 把读取结果转成可写入课表的课程。
List<Course> toCourses(
  List<ReadCourse> items, {
  required int maxWeek,
  required int startId,
}) {
  final courses = <Course>[];
  var id = startId;
  for (final item in items) {
    courses.add(
      Course(
        id: id++,
        name: item.name,
        startWeek: 1,
        endWeek: maxWeek,
        dayOfWeek: item.dayOfWeek,
        startLesson: item.startLesson,
        endLesson: item.endLesson,
        location: item.location,
        rawTime: item.rawText,
        weekPattern: WeekPattern(ranges: [WeekRange(1, maxWeek)]),
      ),
    );
  }
  return courses;
}

/// 读取脚本没读到课表时，给出一句能让人接着往下做的话。
String describeReadFailure(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map && decoded['reason'] == 'no-table') {
      return '这一页上没有课表。先登录，再进入「我的课表」。';
    }
  } catch (_) {
    // 交给调用方给通用提示。
  }
  return '这次没有读到课表，回到课表页面再读一次。';
}
