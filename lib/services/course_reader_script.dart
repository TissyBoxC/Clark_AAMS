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

  /// 取当前正在显示课表的那个 iframe 的地址。
  ///
  /// 教务系统常用「框架 + iframe」结构：外层地址始终是首页，
  /// 用户点导航只是换了 iframe 的内容。这时只读 location.href
  /// 会一直停在首页，刷新也会跳回首页。
  ///
  /// 这里反过来找：哪个 iframe 里有课表表格，就报它的地址。
  /// 同源才能读，跨域读不到就返回空串，由调用方退回主文档地址。
  static const String currentFrameUrl = r'''
(function () {
  try {
    var frames = Array.prototype.slice.call(document.querySelectorAll('iframe'));
    for (var i = 0; i < frames.length; i++) {
      var frame = frames[i];
      var src = frame.getAttribute('src') || '';
      if (!src) {
        continue;
      }
      var doc = null;
      try {
        doc = frame.contentDocument;
      } catch (e) {
        continue;
      }
      if (!doc) {
        continue;
      }
      // 有课表格子的才算，避免把导航栏 iframe 当成课表页
      var tables = doc.querySelectorAll('table');
      var hasSchedule = false;
      for (var t = 0; t < tables.length; t++) {
        if (tables[t].rows && tables[t].rows.length >= 6) {
          hasSchedule = true;
          break;
        }
      }
      if (!hasSchedule) {
        continue;
      }
      try {
        if (frame.contentWindow && frame.contentWindow.location.href) {
          return String(frame.contentWindow.location.href);
        }
      } catch (e) {
        // 跨域时取不到内层地址，退回 src
      }
      try {
        return new URL(src, location.href).href;
      } catch (e) {
        return src;
      }
    }
    return '';
  } catch (error) {
    return '';
  }
})();
''';

  /// 页面结构快照：把框架页的骨架完整记下来。
  ///
  /// 排查「地址锁在首页」这类问题时，需要知道：有几个 iframe、
  /// 各自 src 是什么、能不能读到内容、课表到底在哪一层、跨不跨域。
  /// 这些只能从页面里取，靠猜永远猜不准。
  static const String dumpStructure = r'''
(function () {
  var out = [];
  var push = function (s) { out.push(s); };

  try {
    push('location.href = ' + location.href);
    push('document.title = ' + (document.title || ''));
    push('readyState = ' + document.readyState);

    var tables = document.querySelectorAll('table');
    push('主文档 table 数量 = ' + tables.length);
    for (var t = 0; t < Math.min(tables.length, 5); t++) {
      push('  table[' + t + '] id=' + (tables[t].id || '-') +
           ' class=' + (tables[t].className || '-') +
           ' rows=' + (tables[t].rows ? tables[t].rows.length : 0));
    }

    var frames = document.querySelectorAll('iframe, frame');
    push('iframe/frame 数量 = ' + frames.length);

    for (var i = 0; i < frames.length; i++) {
      var f = frames[i];
      push('--- frame[' + i + '] ---');
      push('  tag = ' + f.tagName);
      push('  id = ' + (f.id || '-'));
      push('  name = ' + (f.getAttribute('name') || '-'));
      push('  class = ' + (f.className || '-'));
      push('  src = ' + (f.getAttribute('src') || '-'));

      var doc = null;
      var crossOrigin = false;
      try {
        doc = f.contentDocument;
      } catch (e) {
        crossOrigin = true;
      }
      if (!doc) {
        try {
          doc = f.contentWindow ? f.contentWindow.document : null;
        } catch (e) {
          crossOrigin = true;
        }
      }

      if (!doc) {
        push('  内容: 读不到（跨域或未加载），crossOrigin=' + crossOrigin);
        continue;
      }

      var href = '';
      try {
        href = f.contentWindow.location.href;
      } catch (e) {
        href = '(读不到)';
      }
      push('  内层 location = ' + href);

      var innerTables = doc.querySelectorAll('table');
      push('  内层 table 数量 = ' + innerTables.length);
      for (var k = 0; k < Math.min(innerTables.length, 5); k++) {
        push('    table[' + k + '] id=' + (innerTables[k].id || '-') +
             ' class=' + (innerTables[k].className || '-') +
             ' rows=' + (innerTables[k].rows ? innerTables[k].rows.length : 0));
      }

      var body = doc.body;
      if (body) {
        var text = (body.innerText || '').replace(/\s+/g, ' ').slice(0, 200);
        push('  正文前 200 字 = ' + text);
      }
    }
  } catch (e) {
    push('快照出错: ' + e);
  }

  return out.join('\n');
})();
''';

  /// 只重载显示课表的那个 iframe，不动主文档。
  ///
  /// 为什么不用 `loadUrl` 跳到 iframe 地址：iframe 的 src 是裸的
  /// `content_xs.aspx`，不带外层框架传的参数，教务系统会判为无效请求，
  /// 反而把登录弄掉。在页面内部重载 iframe，外层框架和 session 都还在。
  ///
  /// 返回 `reloaded` 表示已发起重载；`not-found` 表示没找到课表 iframe，
  /// 由调用方决定退路。
  static const String reloadScheduleFrame = r'''
(function () {
  try {
    var frames = Array.prototype.slice.call(document.querySelectorAll('iframe, frame'));
    for (var i = 0; i < frames.length; i++) {
      var frame = frames[i];
      var doc = null;
      try {
        doc = frame.contentDocument;
      } catch (e) {
        continue;
      }
      if (!doc) {
        continue;
      }
      // 只重载有课表表格的那个，别把导航栏也刷了
      var tables = doc.querySelectorAll('table');
      var hasSchedule = false;
      for (var t = 0; t < tables.length; t++) {
        if (tables[t].rows && tables[t].rows.length >= 6) {
          hasSchedule = true;
          break;
        }
      }
      if (!hasSchedule) {
        continue;
      }
      try {
        frame.contentWindow.location.reload();
        return 'reloaded';
      } catch (e) {
        // 跨域时改 src 也能触发重载
        var src = frame.getAttribute('src') || '';
        if (src) {
          frame.setAttribute('src', src);
          return 'reloaded';
        }
      }
    }
    return 'not-found';
  } catch (error) {
    return 'failed';
  }
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
