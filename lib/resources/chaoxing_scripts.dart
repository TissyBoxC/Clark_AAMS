/// 学习通（超星）作业自动化使用的注入脚本。
///
/// 这些是**注入到第三方页面里执行的 JavaScript 源码**，不是界面文案。
/// 它们原本和 255 个界面常量挤在 `app_strings.dart` 里，两个脚本就占了
/// 599 行（全文 61%），把真正需要人读的文案埋在了下面。
///
/// 拆出来的另一个理由：改动理由与 review 方式完全不同。
/// 改文案是「措辞调整」，改脚本是「对方页面结构变了」——
/// 后者需要逐行看 JS，混在几百行文案里几乎不可能被认真看过。
///
/// 调用方仍通过 `AppStrings.chaoxingAnswerJs` 访问（那边有转发常量），
/// 所以这次拆分不需要改任何调用点。
///
/// 注意：下面的 JS 保留原始缩进，**不要对它做 dedent**——
/// JS 自己的层级缩进是有意义的，削掉会让脚本难以阅读和 review。
abstract final class ChaoxingScripts {
  const ChaoxingScripts._();

  static const chaoxingCollectQuestionsJs = r'''
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

function questionTypeFromCode(value) {
    const code = parseInt(value, 10);
    const map = {
        0: '单选题',
        1: '多选题',
        2: '简答题',
        3: '判断题',
        4: '填空题',
        5: '名词解释',
        6: '论述题',
        7: '计算题',
        8: '其他题',
        9: '分录题',
        10: '资料题',
        11: '连线题',
        14: '完形填空题',
        15: '阅读理解题'
    };
    return map[code] || '';
}

function guessType(text, container) {
    const typeInput = container && container.querySelector('input[id^="answertype"], input[name^="type"]');
    const inputType = questionTypeFromCode(typeInput && typeInput.value);
    if (inputType) return inputType;

    const m = clean(text).match(/(单选题|多选题|判断题|填空题|简答题|问答题|论述题|计算题|名词解释|资料题|材料题|其他题|分录题|连线题|阅读理解题|完形填空题)/);
    return m ? m[1] : '未知题型';
}

function guessNumber(text, index) {
    const m = clean(text).match(/^\s*(\d+)\s*[\.、]|第\s*(\d+)\s*题/);
    return m ? (m[1] || m[2]) : String(index);
}

function isChoiceType(type) {
    return /单选题|多选题|判断题|阅读理解题|完形填空题/.test(type || '');
}

function badOption(text) {
    return !text || /正确答案[:：]|我的答案[:：]|答案解析[:：]|解析[:：]/.test(text);
}

function hasAnswerText(el) {
    const text = clean((el && (el.value || el.innerText || el.textContent)) || '');
    return text && !/未答|未作答|暂无|无/.test(text);
}

function isAnswered(container) {
    const checkedInput = Array.from(container.querySelectorAll('input[type="radio"], input[type="checkbox"]')).some(input =>
        input.checked === true ||
        input.defaultChecked === true ||
        input.getAttribute('checked') === 'checked'
    );
    if (checkedInput) return true;

    if (container.querySelector('[aria-checked="true"], [class*="check_answer"]')) {
        return true;
    }

    const answerBlocks = Array.from(container.querySelectorAll('.stuAnswerContent, .Py_answer, .mark_answer, .myAnswer, .my-answer'));
    if (answerBlocks.some(hasAnswerText)) {
        return true;
    }

    const textInputs = Array.from(container.querySelectorAll('textarea, input:not([type]), input[type="text"]'));
    if (textInputs.some(input => clean(input.value).length > 0)) {
        return true;
    }

    const editorFrames = Array.from(container.querySelectorAll('iframe'));
    for (const frame of editorFrames) {
        try {
            const body = frame.contentDocument && frame.contentDocument.body;
            if (hasAnswerText(body)) return true;
        } catch (e) {
            /* 跨域忽略 */
        }
    }

    return false;
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
        type: guessType(baseText, container),
        content: textOf(stem || container),
        images: imagesOf(stem || container, doc),
        options: [],
        answered: isAnswered(container)
    };

    if (isChoiceType(q.type)) {
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
    }

    if (!stem) {
        q.options.forEach(opt => q.content = q.content.replace(opt, ''));
    }

    q.content = clean(q.content)
        .replace(/^\s*\d+\s*[\.、]\s*/, '')
        .replace(/^[\(（]\s*(单选题|多选题|判断题|填空题|简答题|问答题|论述题|计算题|名词解释|资料题|材料题|其他题|分录题|连线题|阅读理解题|完形填空题)\s*[\)）]\s*/, '')
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
        } else if (q.answered) {
            const index = result.findIndex(item =>
                JSON.stringify([item.type || '', item.content || '', item.options || []]) === key
            );
            if (index !== -1 && !result[index].answered) {
                result[index] = q;
            }
        }
    }
    return result;
}

return JSON.stringify(uniqueQuestions(collectQuestions(document, 0, 6)));
})()
''';

  static const chaoxingAnswerJs = r'''
const targetNumber = String(arguments[0]);
const optionLetters = normalizeLetters(arguments[1]);
const textAnswers = normalizeTextAnswers(arguments[2]);
const targetType = String(arguments[3] || '');
function log(msg) {}

function normalizeLetters(value) {
    const raw = Array.isArray(value) ? value.join(',') : String(value || '');
    const normalized = raw.toUpperCase().replace(/[Ａ-Ｈ]/g, c => String.fromCharCode(c.charCodeAt(0) - 65248));
    const result = [];
    normalized.replace(/[A-H]/g, letter => {
        if (!result.includes(letter)) result.push(letter);
        return letter;
    });
    return result;
}

function normalizeTextAnswers(value) {
    const raw = Array.isArray(value) ? value : [value];
    return raw
        .map(item => String(item || '').trim())
        .filter(Boolean);
}

function clean(text) {
    return (text || '').replace(/\s+/g, ' ').trim();
}

function optionText(el) {
    return clean((el && (el.innerText || el.textContent)) || '');
}

function isChecked(optionElement) {
    const host = optionElement.closest ? (optionElement.closest('li') || optionElement) : optionElement;
    const input = host.querySelector ? host.querySelector('input[type="radio"], input[type="checkbox"]') : null;
    return input?.checked === true ||
        input?.getAttribute('checked') === 'checked' ||
        host.getAttribute?.('aria-checked') === 'true' ||
        /check_answer|checked|selected|active/.test(host.className || '');
}

function clickOption(optionElement, optionLetter) {
    if (!optionElement) return false;

    const host = optionElement.closest ? (optionElement.closest('li') || optionElement) : optionElement;
    let clickable = optionElement;
    if (optionElement.matches?.('li')) {
        clickable = optionElement.querySelector('a, label:not(.before), .after, input, span') || optionElement;
    } else if (!optionElement.matches?.('a, label, input, .after')) {
        clickable = optionElement.querySelector?.('a, label:not(.before), .after, input, span') || optionElement;
    }

    clickable.scrollIntoView?.({ behavior: 'smooth', block: 'center' });
    if (!isChecked(host)) {
        clickable.click();
    }

    if (!isChecked(host)) {
        const fallback = host.querySelector?.('a, label:not(.before), .after, input');
        if (fallback && fallback !== clickable) {
            fallback.click();
        }
    }

    log(`点击选项 ${optionLetter}: ${optionText(optionElement).substring(0, 50)}`);
    return true;
}

function dispatchTextEvents(el) {
    ['input', 'change', 'blur'].forEach(type => {
        try {
            el.dispatchEvent(new Event(type, { bubbles: true }));
        } catch (e) {
            /* 忽略事件兼容问题 */
        }
    });
}

function setTextValue(el, value) {
    if (!el || !value) return false;
    if (el.tagName === 'IFRAME') {
        try {
            const body = el.contentDocument && el.contentDocument.body;
            if (!body) return false;
            body.innerHTML = value;
            body.textContent = value;
            dispatchTextEvents(body);
            return true;
        } catch (e) {
            return false;
        }
    }

    if ('value' in el) {
        el.value = value;
    } else if (el.isContentEditable || el.getAttribute('contenteditable') === 'true') {
        el.innerHTML = value;
        el.textContent = value;
    } else {
        return false;
    }
    dispatchTextEvents(el);
    return true;
}

function findTextTargets(container) {
    const selectors = [
        'textarea',
        '.eidtDiv textarea',
        '.textDIV textarea',
        'input[type="text"]',
        'input:not([type])',
        '[contenteditable="true"]',
        '.edui-body-container',
        '.w-e-text',
        'iframe'
    ];
    const result = [];
    for (const selector of selectors) {
        container.querySelectorAll(selector).forEach(el => {
            if (!result.includes(el)) result.push(el);
        });
    }
    return result.filter(el => {
        const text = optionText(el);
        return !/正确答案[:：]|我的答案[:：]|答案解析[:：]|解析[:：]/.test(text);
    });
}

function fillTextAnswers(container) {
    if (textAnswers.length === 0) {
        log('未收到文本答案');
        return false;
    }

    const targets = findTextTargets(container);
    if (targets.length === 0) {
        log('未找到文本输入区域');
        return false;
    }

    let filled = 0;
    if (targets.length === 1) {
        filled += setTextValue(targets[0], textAnswers.join(' ')) ? 1 : 0;
    } else {
        const count = Math.min(targets.length, textAnswers.length);
        for (let i = 0; i < count; i++) {
            const answer = textAnswers[i];
            filled += setTextValue(targets[i], answer) ? 1 : 0;
        }
    }

    const saveButton = container.querySelector('[onclick*=saveQuestion]');
    if (saveButton) {
        try { saveButton.click(); } catch(e) { /* 保存按钮可不存在 */ }
    }

    return filled > 0;
}

function answerReaderOrFilling(container) {
    if (optionLetters.length === 0) return false;

    const lists = targetType.includes('完形')
        ? Array.from(container.querySelectorAll('.filling_answer'))
        : Array.from(container.querySelectorAll('.reading_answer'));
    if (lists.length === 0) return false;

    let clicked = 0;
    for (let i = 0; i < optionLetters.length; i++) {
        const item = lists[i];
        const letter = optionLetters[i];
        if (!item || !letter) continue;

        const target = item.querySelector(`span.saveSingleSelect[data="${letter}"], [data="${letter}"] a, [data="${letter}"]`);
        if (target) {
            target.click();
            clicked++;
        }
    }
    return clicked > 0;
}

function fillLineAnswers(container) {
    if (textAnswers.length === 0) return false;

    const boxes = Array.from(container.querySelectorAll('.line_answer_ct .selectBox'));
    if (boxes.length === 0) return false;

    let clicked = 0;
    for (let i = 0; i < boxes.length; i++) {
        const answer = textAnswers[i] || textAnswers[0];
        const box = boxes[i];
        const target = box.querySelector(`li[data="${answer}"] a, li[data="${answer}"]`);
        if (target) {
            target.click();
            clicked++;
        }
    }
    return clicked > 0;
}



// 递归遍历所有frame，找到指定题号的题目容器，然后找到对应选项并点击
function selectOptionByNumber(doc) {
    if (optionLetters.length === 0 && textAnswers.length === 0) {
        log('未收到有效答案');
        return false;
    }

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

    if ((targetType.includes('阅读理解') || targetType.includes('完形填空')) && answerReaderOrFilling(targetContainer)) {
        return true;
    }

    if (targetType.includes('连线') && fillLineAnswers(targetContainer)) {
        return true;
    }

    if (optionLetters.length === 0) {
        return fillTextAnswers(targetContainer);
    }

    // 3. 查找选项列表（与用户原版相同）
    const optionSelectors = [
        'ul li .after', 'ul li label:not(.before)', '.answerBg .answer_p',
        '.answer_p', '.answerList.singleChoice li', '.clearfix.answerBg .fl.answer_p',
        '.stem_answer .answer_p', '.Zy_ulTop li a', '.mark_letter li', '.qtDetail li',
        '.option li', '.options li', '.answerList li', '.choice li', '.ulTop li', 'li'
    ];
    let options = null;
    for (const sel of optionSelectors) {
        const opts = targetContainer.querySelectorAll(sel);
        if (opts.length >= 2) {
            // 过滤掉明显不是选项的文本（如“正确答案：”）
            const filtered = Array.from(opts).filter(opt => {
                const text = optionText(opt);
                return text &&
                    !/正确答案[:：]/.test(text) &&
                    !/我的答案[:：]/.test(text) &&
                    !/答案解析[:：]|解析[:：]/.test(text);
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

    let clicked = 0;
    for (const optionLetter of optionLetters) {
        const optionIndex = optionLetter.charCodeAt(0) - 65;
        if (optionIndex < 0 || optionIndex >= options.length) {
            log(`选项索引 ${optionIndex} 超出范围 (0-${options.length - 1})`);
            continue;
        }
        try {
            if (clickOption(options[optionIndex], optionLetter)) {
                clicked++;
            }
        } catch(e) {
            log(`点击失败: ${e.message}`);
        }
    }

    return clicked === optionLetters.length;
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
return JSON.stringify({ success: success, expected: optionLetters.length });
''';
}
