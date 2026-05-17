import 'dart:convert';

class ChaoxingQuestion {
  const ChaoxingQuestion({
    required this.number,
    required this.type,
    required this.content,
    required this.images,
    required this.options,
  });

  final String number;
  final String type;
  final String content;
  final List<Map<String, Object?>> images;
  final List<String> options;

  factory ChaoxingQuestion.fromJson(Map<String, Object?> json, int index) {
    final imagesValue = json['images'];
    final optionsValue = json['options'];
    return ChaoxingQuestion(
      number: _asNonEmptyString(json['number']) ?? '$index',
      type: _asNonEmptyString(json['type']) ?? '未知题型',
      content: _asNonEmptyString(json['content']) ?? '',
      images: [
        if (imagesValue is List)
          for (final item in imagesValue)
            if (item is Map<String, Object?>)
              item
            else if (item is Map)
              item.cast<String, Object?>(),
      ],
      options: [
        if (optionsValue is List)
          for (final item in optionsValue)
            if (item != null) item.toString(),
      ],
    );
  }

  static String? _asNonEmptyString(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}

class ChaoxingAnswerClickResult {
  const ChaoxingAnswerClickResult({
    required this.success,
  });

  final bool success;

  factory ChaoxingAnswerClickResult.fromJson(Object? value) {
    Map<String, Object?> map;
    if (value is Map<String, Object?>) {
      map = value;
    } else if (value is Map) {
      map = value.cast<String, Object?>();
    } else {
      map = const {};
    }
    return ChaoxingAnswerClickResult(
      success: map['success'] == true,
    );
  }
}

class ChaoxingQuestionAutomation {

  const ChaoxingQuestionAutomation._();

  static List<ChaoxingQuestion> parseQuestions(Object? value) {
    final decoded = _decodeJavaScriptJson(value);
    if (decoded is! List) {
      return const [];
    }
    final questions = <ChaoxingQuestion>[];
    for (var i = 0; i < decoded.length; i++) {
      final item = decoded[i];
      if (item is Map<String, Object?>) {
        questions.add(ChaoxingQuestion.fromJson(item, i + 1));
      } else if (item is Map) {
        questions.add(
          ChaoxingQuestion.fromJson(item.cast<String, Object?>(), i + 1),
        );
      }
    }
    return _uniqueQuestions(questions);
  }

  static ChaoxingAnswerClickResult parseAnswerClickResult(Object? value) {
    return ChaoxingAnswerClickResult.fromJson(_decodeJavaScriptJson(value));
  }

  static String? extractLetter(Object? aiResult) {
    if (aiResult == null) {
      return null;
    }

    String aiResultText;
    if (aiResult is Map) {
      final value =
          aiResult['answer'] ??
          aiResult['答案'] ??
          aiResult['letter'] ??
          aiResult['option'];
      if (value != null) {
        aiResultText = value.toString();
      } else {
        aiResultText = jsonEncode(aiResult);
      }
    } else {
      aiResultText = aiResult.toString();
    }

    final match = RegExp(r'\b[A-H]\b').firstMatch(aiResultText.toUpperCase());
    return match?.group(0);
  }

  static String answerQuestionScript(String number, String letter) {
    return '''
(() => {
  return (function() {
$answerJs
  })(${jsonEncode(number)}, ${jsonEncode(letter)});
})()
''';
  }

  static Object? _decodeJavaScriptJson(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is List || value is Map) {
      return value;
    }
    Object? current = value;
    for (var i = 0; i < 2; i++) {
      if (current is! String) {
        return current;
      }
      final text = current.trim();
      if (text.isEmpty || text == 'null' || text == 'undefined') {
        return null;
      }
      try {
        current = jsonDecode(text);
      } catch (_) {
        return current;
      }
    }
    return current;
  }

  static List<ChaoxingQuestion> _uniqueQuestions(
    List<ChaoxingQuestion> questions,
  ) {
    final result = <ChaoxingQuestion>[];
    final seen = <String>{};
    for (final q in questions) {
      final key = jsonEncode([q.type, q.content, q.options]);
      if (seen.add(key)) {
        result.add(q);
      }
    }
    return result;
  }

  static const String collectQuestionsJs = r'''
(() => {
function clean(text) {
    return (text || '').replace(/\s+/g, ' ').trim();
}

function textOf(el) {
    if (!el) return '';
    const cloned = el.cloneNode(true);
    cloned.querySelectorAll(`
        .stuAnswerContent, .rightAnswerContent, .qtAnalysis, .analysis,
        .answer, .answerCon, .mark_answer, .marking_dui, .marking_cuo,
        .totalScore, .score, .Py_answer, .Py_answerRight, .Py_answerWrong
    `).forEach(x => x.remove());
    return clean(cloned.textContent);
}

function imagesOf(el, doc) {
    return Array.from((el || doc).querySelectorAll('img')).map((img, i) => ({
        index: i + 1,
        src: img.getAttribute('src') || img.getAttribute('data-original') || img.getAttribute('data-src') || '',
        alt: img.getAttribute('alt') || ''
    })).filter(x => x.src);
}

function guessType(text) {
    const m = clean(text).match(/(单选题|多选题|判断题|填空题|简答题|问答题|论述题|计算题|阅读理解题|完形填空题)/);
    return m ? m[1] : '未知题型';
}

function guessNumber(text, index) {
    const m = clean(text).match(/^\s*(\d+)\s*[\.、]|第\s*(\d+)\s*题/);
    return m ? (m[1] || m[2]) : String(index);
}

function badOption(text) {
    return !text || /正确答案[:：]|我的答案[:：]|答案解析[:：]|解析[:：]/.test(text);
}

function findContainers(doc) {
    const selectors = [
        '.questionLi', '.question-li', '.questionItem', '.question-item',
        '.TiMu', '.tiMu', '.question', '.work-question', '.mark_item', '.markItem',
        '.Cy_ulTop', '.py-mian1', '.zquestions .Py-mian1'
    ];

    for (const selector of selectors) {
        const nodes = Array.from(doc.querySelectorAll(selector));
        if (nodes.length) return nodes;
    }

    const set = new Set();
    doc.querySelectorAll('.mark_name, .qtContent, .questionStem, .stem').forEach(node => {
        let p = node;
        for (let i = 0; i < 5 && p; i++, p = p.parentElement) {
            if (p.innerText && p.innerText.length > 20) {
                set.add(p);
                break;
            }
        }
    });
    return Array.from(set);
}

function parseQuestion(container, index, doc) {
    const title = container.querySelector('.mark_name, .question-title, .tit, .stem-title, .clearfix');
    const stem = container.querySelector('.qtContent, .questionStem, .stem, .content');
    const baseText = textOf(title || container);

    const q = {
        number: guessNumber(baseText, index),
        type: guessType(baseText),
        content: textOf(stem || container),
        images: imagesOf(stem || container, doc),
        options: []
    };

    const optionSelectors = [
        '.mark_letter li', '.qtDetail li', '.option li', '.options li',
        '.answerList li', '.choice li', '.ulTop li', 'li'
    ];

    for (const selector of optionSelectors) {
        const nodes = Array.from(container.querySelectorAll(selector)).filter(node => {
            const text = textOf(node);
            return !badOption(text) && (/^[A-H][\.、\s]/.test(text) || node.querySelector('input[type="radio"], input[type="checkbox"]'));
        });
        if (nodes.length >= 2) {
            q.options = nodes.map((node, i) => {
                let text = textOf(node)
                    .replace(/正确答案[:：].*$/g, '')
                    .replace(/我的答案[:：].*$/g, '')
                    .replace(/答案[:：].*$/g, '')
                    .replace(/解析[:：].*$/g, '')
                    .trim();
                return /^[A-H][\.、\s]/.test(text) ? text : `${String.fromCharCode(65 + i)}. ${text}`;
            }).filter(Boolean);
            break;
        }
    }

    if (!stem) {
        q.options.forEach(opt => q.content = q.content.replace(opt, ''));
    }

    q.content = clean(q.content)
        .replace(/^\s*\d+\s*[\.、]\s*/, '')
        .replace(/^[\(（]\s*(单选题|多选题|判断题|填空题|简答题|问答题|论述题|计算题)\s*[\)）]\s*/, '')
        .trim();

    return q.content ? q : null;
}

function parseCurrentFrame(doc) {
    try {
        return findContainers(doc).map((container, index) => parseQuestion(container, index + 1, doc)).filter(Boolean);
    } catch (e) {
        return [];
    }
}

function collectQuestions(doc, depth, maxDepth) {
    if (depth > maxDepth) {
        return [];
    }

    let questions = parseCurrentFrame(doc);
    let frames = [];
    try {
        frames = Array.from(doc.querySelectorAll('iframe'));
    } catch (e) {
        frames = [];
    }

    for (let i = 0; i < frames.length; i++) {
        try {
            const frameDoc = frames[i].contentDocument || frames[i].contentWindow.document;
            if (frameDoc) {
                questions = questions.concat(collectQuestions(frameDoc, depth + 1, maxDepth));
            }
        } catch (e) {
            /* 跨域忽略 */
        }
    }

    return questions;
}

function uniqueQuestions(questions) {
    const result = [];
    const seen = new Set();
    for (const q of questions) {
        const key = JSON.stringify([q.type || '', q.content || '', q.options || []]);
        if (!seen.has(key)) {
            seen.add(key);
            result.push(q);
        }
    }
    return result;
}

return JSON.stringify(uniqueQuestions(collectQuestions(document, 0, 6)));
})()
''';

  static const String answerJs = r'''
const targetNumber = String(arguments[0]);
const optionLetter = String(arguments[1] || '').toUpperCase();
function log(msg) {}

// 递归遍历所有frame，找到指定题号的题目容器，然后找到对应选项并点击
function selectOptionByNumber(doc) {
    // 1. 查找所有题目容器（与用户原版相同的选择器）
    const questionSelectors = [
        '.questionLi', '.question-li', '.questionItem', '.question-item',
        '.TiMu', '.tiMu', '.question', '.work-question', '.mark_item', '.markItem'
    ];
    let containers = [];
    for (const sel of questionSelectors) {
        const elems = doc.querySelectorAll(sel);
        if (elems.length > 0) {
            containers = Array.from(elems);
            log(`使用选择器 "${sel}" 找到 ${containers.length} 个容器`);
            break;
        }
    }
    if (containers.length === 0) {
        // 备用：查找包含题干特征的元素（与用户原版相同）
        const titleNodes = doc.querySelectorAll('.mark_name, .qtContent, .stem-title');
        const set = new Set();
        titleNodes.forEach(node => {
            let p = node;
            for (let i = 0; i < 5 && p; i++) {
                if (p.innerText && p.innerText.length > 20) {
                    set.add(p);
                    break;
                }
                p = p.parentElement;
            }
        });
        containers = Array.from(set);
        log(`通过 mark_name 父级推断找到 ${containers.length} 个容器`);
    }
    if (containers.length === 0) {
        log('未找到任何题目容器');
        return false;
    }

    // 2. 根据题号匹配目标容器
    let targetContainer = null;
    for (const container of containers) {
        // 从容器中提取题号（优先从 .mark_name 等元素）
        const titleEl = container.querySelector('.mark_name, .question-title, .tit, .stem-title, .clearfix');
        let titleText = '';
        if (titleEl) {
            titleText = titleEl.innerText || titleEl.textContent || '';
        } else {
            titleText = container.innerText || container.textContent || '';
        }
        const match = titleText.match(/^\s*(\d+)\s*[\.、]|第\s*(\d+)\s*题/);
        let num = null;
        if (match) {
            num = match[1] || match[2];
            log(`提取到题号 ${num}，目标题号 ${targetNumber}`);
        }
        if (num && String(num) === targetNumber) {
            targetContainer = container;
            log(`找到匹配的题目容器，题号 ${num}`);
            break;
        }
    }
    if (!targetContainer) {
        log(`未找到题号为 ${targetNumber} 的容器`);
        return false;
    }

    // 3. 查找选项列表（与用户原版相同）
    const optionSelectors = [
        '.answer_p', '.answerList.singleChoice li', '.clearfix.answerBg .fl.answer_p',
        '.stem_answer .answer_p', '.Zy_ulTop li a', '.mark_letter li', '.qtDetail li',
        '.option li', '.options li', '.answerList li', '.choice li', '.ulTop li'
    ];
    let options = null;
    for (const sel of optionSelectors) {
        const opts = targetContainer.querySelectorAll(sel);
        if (opts.length >= 2) {
            // 过滤掉明显不是选项的文本（如“正确答案：”）
            const filtered = Array.from(opts).filter(opt => {
                const text = opt.innerText.trim();
                return text && !/正确答案[:：]/.test(text) && !/我的答案[:：]/.test(text);
            });
            if (filtered.length >= 2) {
                options = filtered;
                log(`选项选择器 "${sel}" 找到 ${options.length} 个选项`);
                break;
            }
        }
    }
    if (!options || options.length === 0) {
        log('未找到选项列表');
        return false;
    }

    // 4. 根据选项字母确定索引（A->0, B->1, C->2, ...）
    const optionIndex = optionLetter.charCodeAt(0) - 65;
    if (optionIndex < 0 || optionIndex >= options.length) {
        log(`选项索引 ${optionIndex} 超出范围 (0-${options.length-1})`);
        return false;
    }
    const optionElement = options[optionIndex];
    const optText = (optionElement.innerText || optionElement.textContent || '').substring(0, 50);
    log(`目标选项: ${optionLetter}, 索引 ${optionIndex}, 文本: ${optText}`);

    // 5. 模拟用户原版的点击逻辑
    let clickable = optionElement;
    if (optionElement.tagName === 'LI') {
        const inner = optionElement.querySelector('a, span, input');
        if (inner) clickable = inner;
    }
    clickable.scrollIntoView({ behavior: 'smooth', block: 'center' });
    try {
        clickable.click();
        log(`成功点击选项 ${optionLetter}`);
        return true;
    } catch(e) {
        log(`点击失败: ${e.message}`);
        return false;
    }
}

// 递归遍历所有frame
function findAndClickInFrames(doc) {
    if (selectOptionByNumber(doc)) return true;
    const frames = doc.querySelectorAll('iframe');
    for (let i = 0; i < frames.length; i++) {
        try {
            const frameDoc = frames[i].contentDocument;
            if (frameDoc && findAndClickInFrames(frameDoc)) {
                return true;
            }
        } catch(e) { /* 跨域忽略 */ }
    }
    return false;
}

const success = findAndClickInFrames(document);
return JSON.stringify({ success: success });
''';
}
