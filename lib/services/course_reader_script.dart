import 'dart:convert';

/// 注入学校页面的脚本集合。
///
/// 这里**不做课程解析**。App 端只负责把页面内容原样交给后端，
/// 哪张表是课表、怎么切分节次，全部由后端判断。
///
/// 之前 App 里用 JS 猜"哪张表是课表"，实测把表头（星期一/星期二…）
/// 当成了课程，读出 31 门假课。这类规则只应该存在一份，放在后端，
/// 有真实页面样本和测试撑着。
class CourseReaderScript {
  const CourseReaderScript._();

  /// 在页面里点开「课表」导航项。
  ///
  /// 导航菜单往往在另一个 iframe 里（框架页常见），只查主文档会找不到，
  /// 所以同样要挨个内嵌页找。找到就点，点完由页面自己去加载课表。
  static const String openScheduleTab = r'''
(function () {
  var wanted = ['课表', '我的课表', '本学期课表', '学生课表'];

  var docs = [document];
  var collect = function (root) {
    var frames = root.querySelectorAll('iframe, frame');
    for (var i = 0; i < frames.length; i++) {
      var doc = null;
      try {
        doc = frames[i].contentDocument;
      } catch (e) {
        continue;
      }
      if (doc) {
        docs.push(doc);
      }
    }
  };
  collect(document);
  for (var d = 0; d < docs.length && d < 8; d++) {
    collect(docs[d]);
  }

  for (var s = 0; s < docs.length; s++) {
    var nodes = docs[s].querySelectorAll('a, button, li, span');
    for (var i = 0; i < nodes.length; i++) {
      var text = (nodes[i].innerText || '').trim();
      for (var w = 0; w < wanted.length; w++) {
        if (text === wanted[w]) {
          nodes[i].click();
          return 'clicked';
        }
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
  // 真正的课表表格长这样：table#Table1.schedule。
  // 首页的 table#Table6（学业进度）行数也不少，光看行数会认错。
  var looksLikeScheduleDoc = function (doc) {
    var tables = doc.querySelectorAll('table');
    for (var t = 0; t < tables.length; t++) {
      var cls = ' ' + (tables[t].className || '') + ' ';
      if (cls.indexOf(' schedule ') >= 0 && tables[t].rows && tables[t].rows.length >= 6) {
        return true;
      }
    }
    return false;
  };

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
      /*
       * 先看内层地址。正方的课表页是 xskbcx.aspx，这个最可靠。
       * 不能只看"有没有 table"：首页 content_xs.aspx 里的 table#Table6
       * 也有 7 行（学业进度），按行数判断会在首页就报成课表页。
       */
      var inner = '';
      try {
        inner = String(frame.contentWindow.location.href || '');
      } catch (e) {
        inner = '';
      }
      if (inner.indexOf('xskbcx') < 0) {
        // 地址读不到或不认识，再退回看有没有真正的课表格子
        if (!looksLikeScheduleDoc(doc)) {
          continue;
        }
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
  /// 判断"哪个 iframe 是课表"不能只看有没有 table：
  /// 首页的 content_xs.aspx 里也有 table#Table6（7 行，是学业进度），
  /// 按行数找会在首页误刷。这里改成看内层地址——带 `xskbcx` 的才是课表页。
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
      var innerUrl = '';
      try {
        doc = frame.contentDocument;
        innerUrl = frame.contentWindow.location.href || '';
      } catch (e) {
        continue;
      }
      if (!doc || !innerUrl) {
        continue;
      }
      // 正方教务的课表页是 xskbcx.aspx，别的页面不是
      if (innerUrl.indexOf('xskbcx') < 0) {
        continue;
      }
      try {
        frame.contentWindow.location.reload();
        return 'reloaded';
      } catch (e) {
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

  /// 只抓页面 HTML，交给后端解析。
  ///
  /// 这个脚本刻意**不做任何解析**——它只把页面内容原样交出来。
  /// 判断哪张表是课表、怎么切分节次，全部由后端负责。
  ///
  /// 之前 App 里自己用 JS 猜"哪张表是课表"，实测把表头
  /// （星期一/星期二…）当成了课程，读出 31 门假课。
  ///
  /// 返回 `{html, frames:[{src,id,html}]}`：
  /// - `html` 是主文档的 outerHTML
  /// - `frames` 是每个同源内嵌页的地址、id 和内容。课表常在有
  ///   实际内容的 iframe 里，只传外层会拿不到表格。
  static const String captureHtml = r'''
(function () {
  try {
    var frames = [];
    var nodes = document.querySelectorAll('iframe, frame');
    for (var i = 0; i < nodes.length; i++) {
      var node = nodes[i];
      var doc = null;
      try {
        doc = node.contentDocument;
      } catch (e) {
        continue;
      }
      if (!doc || !doc.documentElement) {
        continue;
      }
      var inner = '';
      try {
        inner = String(node.contentWindow.location.href || '');
      } catch (e) {
        inner = '';
      }
      frames.push({
        src: inner || node.getAttribute('src') || '',
        id: node.id || '',
        html: doc.documentElement.outerHTML
      });
    }

    return JSON.stringify({
      html: document.documentElement.outerHTML,
      frames: frames
    });
  } catch (error) {
    return JSON.stringify({ html: '', frames: [], error: String(error) });
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
