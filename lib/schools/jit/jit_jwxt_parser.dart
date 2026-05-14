import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

class JitJwxtRawCourse {
  const JitJwxtRawCourse({
    required this.name,
    required this.teacher,
    required this.position,
    required this.day,
    required this.startSection,
    required this.endSection,
    required this.weeks,
    required this.rawTime,
  });

  final String name;
  final String teacher;
  final String position;
  final int day;
  final int? startSection;
  final int? endSection;
  final List<int> weeks;
  final String rawTime;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'name': name,
      'teacher': teacher,
      'position': position,
      'day': day,
      'startSection': startSection,
      'endSection': endSection,
      'weeks': weeks,
      'rawTime': rawTime,
    };
  }
}

class JitJwxtParser {
  const JitJwxtParser._();

  static const baseUrl = 'https://jwxt.jit.edu.cn';
  static const loginUrl = '$baseUrl/default2.aspx';

  static bool pageHasTable6(String html) {
    final document = html_parser.parse(html);
    return document.querySelector('table#Table6') != null;
  }

  static int? parseDay(String text) {
    final normalized = text.trim();
    if (normalized.isEmpty) {
      return null;
    }

    const weekdayMap = <String, int>{
      '星期一': 1,
      '星期二': 2,
      '星期三': 3,
      '星期四': 4,
      '星期五': 5,
      '星期六': 6,
      '星期日': 7,
      '星期天': 7,
      '周一': 1,
      '周二': 2,
      '周三': 3,
      '周四': 4,
      '周五': 5,
      '周六': 6,
      '周日': 7,
      '周天': 7,
      '一': 1,
      '二': 2,
      '三': 3,
      '四': 4,
      '五': 5,
      '六': 6,
      '日': 7,
      '天': 7,
    };

    for (final entry in weekdayMap.entries) {
      if (normalized.contains(entry.key)) {
        return entry.value;
      }
    }

    return null;
  }

  static List<int> parseWeeks(String weekText) {
    final weeks = <int>[];
    if (weekText.trim().isEmpty) {
      return weeks;
    }

    final rawText = weekText.trim();
    final text = rawText
        .replaceAll('（', '')
        .replaceAll('）', '')
        .replaceAll('(', '')
        .replaceAll(')', '')
        .replaceAll('第', '')
        .replaceAll('周', '')
        .replaceAll(' ', '');

    final odd = rawText.contains('单');
    final even = rawText.contains('双');

    final rangeMatch = RegExp(r'(\d+)\s*[-~至]\s*(\d+)').firstMatch(text);
    if (rangeMatch != null) {
      final startWeek = int.parse(rangeMatch.group(1)!);
      final endWeek = int.parse(rangeMatch.group(2)!);

      for (var week = startWeek; week <= endWeek; week++) {
        if (odd && week.isEven) {
          continue;
        }
        if (even && week.isOdd) {
          continue;
        }
        weeks.add(week);
      }

      return weeks;
    }

    final singleMatch = RegExp(r'(\d+)').firstMatch(text);
    if (singleMatch != null) {
      weeks.add(int.parse(singleMatch.group(1)!));
    }

    return weeks;
  }

  static ({int? startSection, int? endSection, List<int> weeks}) parseTimeText(
    String timeText,
  ) {
    int? startSection;
    int? endSection;
    var weeks = <int>[];

    if (timeText.trim().isEmpty) {
      return (startSection: startSection, endSection: endSection, weeks: weeks);
    }

    final text = timeText.trim();
    final sectionMatch = RegExp(r'(\d+)\s*[-~至]\s*(\d+)\s*节').firstMatch(text);

    if (sectionMatch != null) {
      startSection = int.parse(sectionMatch.group(1)!);
      endSection = int.parse(sectionMatch.group(2)!);
    } else {
      final singleMatch = RegExp(r'(\d+)\s*节').firstMatch(text);
      if (singleMatch != null) {
        final section = int.parse(singleMatch.group(1)!);
        startSection = section;
        endSection = section;
      }
    }

    final weekMatch = RegExp(r'[（(](.*?周.*?)[）)]').firstMatch(text);
    if (weekMatch != null) {
      weeks = parseWeeks(weekMatch.group(1)!);
    }

    return (startSection: startSection, endSection: endSection, weeks: weeks);
  }

  static List<JitJwxtRawCourse> parseCourseTd(dom.Element td, int day) {
    final courses = <JitJwxtRawCourse>[];
    final courseBlocks = td.querySelectorAll('p.kblsbk');
    if (courseBlocks.isEmpty) {
      return courses;
    }

    for (final block in courseBlocks) {
      final timeSpan = block.querySelector('span.time');
      final nameSpan = block.querySelector('span.kejie');
      final positionSpan = block.querySelector('span.didian');
      final teacherSpan =
          block.querySelector('span.teacher') ??
          block.querySelector('span.jiaoshi') ??
          block.querySelector('span.js') ??
          block.querySelector('span.teach');

      final timeText = timeSpan?.text.trim() ?? '';
      final courseName = nameSpan?.text.trim() ?? '';
      final position = positionSpan?.text.trim() ?? '';
      final teacher = teacherSpan?.text.trim() ?? '';

      if (courseName.isEmpty) {
        continue;
      }

      final timeInfo = parseTimeText(timeText);
      courses.add(
        JitJwxtRawCourse(
          name: courseName,
          teacher: teacher,
          position: position,
          day: day,
          startSection: timeInfo.startSection,
          endSection: timeInfo.endSection,
          weeks: timeInfo.weeks,
          rawTime: timeText,
        ),
      );
    }

    return courses;
  }

  static List<JitJwxtRawCourse> parseIndexChartsTable(String html) {
    final document = html_parser.parse(html);

    final table =
        document.querySelector(
          'body#index-charts '
          'form#form1 '
          'div.row.clsntc '
          'div#divQtxx '
          'div#divkbxs '
          'div.com-sec '
          'div.comcon-sec '
          'div.class-table '
          'table#Table6',
        ) ??
        document.querySelector('table#Table6') ??
        document.querySelector('.class-table table');

    if (table == null) {
      throw const FormatException('未找到课表 table#Table6');
    }

    final tbody = table.querySelector('tbody');
    if (tbody == null) {
      throw const FormatException('未找到 table#Table6 的 tbody');
    }

    final courses = <JitJwxtRawCourse>[];
    for (final tr in tbody.children.where(
      (element) => element.localName == 'tr',
    )) {
      final tds = tr.children
          .where((element) => element.localName == 'td')
          .toList();
      if (tds.isEmpty) {
        continue;
      }

      final day = parseDay(tds.first.text.trim());
      if (day == null) {
        continue;
      }

      for (final td in tds.skip(1)) {
        courses.addAll(parseCourseTd(td, day));
      }
    }

    final uniqueCourses = <JitJwxtRawCourse>[];
    final seen = <String>{};
    for (final course in courses) {
      final key = [
        course.name,
        course.day,
        course.startSection,
        course.endSection,
        course.position,
        course.weeks.join(','),
      ].join('|');

      if (seen.contains(key)) {
        continue;
      }

      seen.add(key);
      uniqueCourses.add(course);
    }

    return uniqueCourses;
  }
}
