import 'dart:convert';

/// 课表解析插件：注入学校页面后读取页面上的课程信息。
///
/// 只在「课表页」里运行，读到的内容一律先折算成纯文本，
/// 页面自己不再回传任何可执行代码。解析规则集中在这个文件，
/// 修一所学校只需要改这里的条目。
class CourseReaderScript {
  const CourseReaderScript._();

  /// 注入到学校页面的读取脚本。
  ///
  /// 该脚本做三件事：
  /// 1. 找出课表所在的表格或列表容器；
  /// 2. 按星期 × 节次读取每个格子的课程文字；
  /// 3. 把结果整理成 `{ name, day, start, end, room }` 的数组返回。
  static const String readCourses = r'''
(function () {
  try {
    var pick = function (node) {
      return node ? (node.innerText || node.textContent || '').trim() : '';
    };

    var tables = Array.prototype.slice.call(document.querySelectorAll('table'));
    var best = null;
    var bestScore = 0;

    tables.forEach(function (table) {
      var rows = table.rows || [];
      if (rows.length < 6) {
        return;
      }
      var maxCells = 0;
      for (var i = 0; i < rows.length; i++) {
        maxCells = Math.max(maxCells, rows[i].cells.length);
      }
      var score = maxCells * rows.length;
      if (maxCells >= 7 && score > bestScore) {
        bestScore = score;
        best = table;
      }
    });

    if (!best) {
      return JSON.stringify({ ok: false, reason: 'no-table' });
    }

    var lessons = [];
    var rows = best.rows;
    for (var r = 0; r < rows.length; r++) {
      var cells = rows[r].cells;
      if (!cells || cells.length < 7) {
        continue;
      }
      var headText = pick(cells[0]);
      var anchor = cells.length >= 8 ? 1 : 0;
      for (var c = 0; c < Math.min(7, cells.length - anchor); c++) {
        var cell = cells[c + anchor];
        var text = pick(cell);
        if (!text || text.length < 2) {
          continue;
        }
        var rowspan = cell.rowSpan || 1;
        lessons.push({
          name: text.split('\n')[0].slice(0, 60),
          text: text,
          rowIndex: r,
          dayIndex: c,
          span: rowspan,
          headText: headText,
        });
      }
    }

    return JSON.stringify({
      ok: true,
      lessons: lessons,
      title: document.title || '',
      url: location.href,
    });
  } catch (error) {
    return JSON.stringify({ ok: false, reason: 'script-failed' });
  }
})();
''';

  /// 在页面里点开一个导航项（例如"我的课表"），找不到就算了。
  static const String openScheduleTab = r'''
(function () {
  var wanted = ['课表', '我的课表', '本学期课表', '学生课表'];
  var nodes = document.querySelectorAll('a, button, li, span');
  for (var i = 0; i < nodes.length; i++) {
    var text = (nodes[i].innerText || '').trim();
    for (var w = 0; w < wanted.length; w++) {
      if (text === wanted[w]) {
        nodes[i].click();
        return 'clicked';
      }
    }
  }
  return 'no-match';
})();
''';

  /// 使用哪所学校的内置规则；没有专属规则时返回 `null`。
  static CourseReaderRule? ruleFor(String schoolId) => _rules[schoolId];

  static const Map<String, CourseReaderRule> _rules = {
    'default': CourseReaderRule(
      key: 'default',
      knownSchedulePath: '',
      description: '按页面上的课表表格读取',
    ),
  };

  /// 把插件返回的原始文字整理成可读结果。
  static List<Map<String, Object?>> normalize(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return const [];
    }
    final lessons = decoded['lessons'];
    if (lessons is! List) {
      return const [];
    }
    return [
      for (final item in lessons)
        if (item is Map) item.cast<String, Object?>(),
    ];
  }
}

/// 一所学校的读取规则。
class CourseReaderRule {
  const CourseReaderRule({
    required this.key,
    required this.knownSchedulePath,
    required this.description,
  });

  final String key;
  final String knownSchedulePath;
  final String description;
}
