import 'dart:convert';

import '../resources/app_strings.dart';

class ChaoxingQuestion {
  const ChaoxingQuestion({
    required this.number,
    required this.type,
    required this.content,
    required this.images,
    required this.options,
    required this.answered,
  });

  final String number;
  final String type;
  final String content;
  final List<Map<String, Object?>> images;
  final List<String> options;
  final bool answered;

  factory ChaoxingQuestion.fromJson(Map<String, Object?> json, int index) {
    final imagesValue = json['images'];
    final optionsValue = json['options'];
    return ChaoxingQuestion(
      number: _asNonEmptyString(json['number']) ?? '$index',
      type: _asNonEmptyString(json['type']) ?? AppStrings.unknownQuestionType,
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
      answered: json['answered'] == true,
    );
  }

  static String? _asNonEmptyString(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}

class ChaoxingAnswerClickResult {
  const ChaoxingAnswerClickResult({required this.success});

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
    return ChaoxingAnswerClickResult(success: map['success'] == true);
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

  static List<String> extractLetters(
    Object? aiResult, {
    required String questionType,
    required List<String> options,
  }) {
    if (aiResult == null) {
      return const [];
    }

    final candidates = _answerCandidates(aiResult);
    final isJudgement = questionType.contains('判断');

    for (final candidate in candidates) {
      final letters = _lettersFromValue(candidate);
      if (letters.isNotEmpty) {
        return letters;
      }

      if (isJudgement) {
        final judgementLetters = _judgementLetters(candidate, options);
        if (judgementLetters.isNotEmpty) {
          return judgementLetters;
        }
      }
    }

    return const [];
  }

  static List<String> extractTextAnswers(
    Object? aiResult, {
    required String questionType,
  }) {
    final answers = <String>[];
    for (final candidate in _answerCandidates(aiResult)) {
      for (final text in _stringsFromValue(candidate)) {
        final cleaned = _cleanAnswerText(text);
        if (cleaned.isEmpty) {
          continue;
        }
        final clarkParts = _splitClarkMarkedAnswer(cleaned);
        if (clarkParts.isNotEmpty) {
          answers.addAll(clarkParts);
        } else if (_shouldSplitTextAnswer(questionType)) {
          answers.addAll(_splitTextAnswer(cleaned));
        } else {
          answers.add(_cleanSplitAnswerPart(cleaned));
        }
      }
      if (answers.isNotEmpty) {
        break;
      }
    }
    return answers;
  }

  static bool isChoiceQuestion(ChaoxingQuestion question) {
    final type = question.type;
    if (type.contains('填空') ||
        type.contains('简答') ||
        type.contains('问答') ||
        type.contains('论述') ||
        type.contains('计算') ||
        type.contains('名词解释') ||
        type.contains('资料') ||
        type.contains('材料') ||
        type.contains('其他') ||
        type.contains('分录') ||
        type.contains('连线')) {
      return false;
    }

    return type.contains('单选') ||
        type.contains('多选') ||
        type.contains('判断') ||
        type.contains('阅读理解') ||
        type.contains('完形填空') ||
        question.options.isNotEmpty;
  }

  static String answerQuestionScript(
    String number, {
    required List<String> letters,
    required List<String> textAnswers,
    required String questionType,
  }) {
    return '''
(() => {
  return (function() {
$answerJs
  })(${jsonEncode(number)}, ${jsonEncode(letters)}, ${jsonEncode(textAnswers)}, ${jsonEncode(questionType)});
})()
''';
  }

  static List<Object?> _answerCandidates(Object? value) {
    if (value is Map) {
      const keys = [
        'answer',
        AppStrings.chaoxingAnswerKey,
        'letter',
        'letters',
        'option',
        'options',
        'choice',
        'choices',
        'result',
        'data',
      ];
      final result = <Object?>[
        for (final key in keys)
          if (value.containsKey(key)) value[key],
      ];
      if (result.isNotEmpty) {
        return result;
      }
      return [jsonEncode(value)];
    }
    return [value];
  }

  static List<String> _lettersFromValue(Object? value) {
    final texts = _stringsFromValue(value);
    final result = <String>[];
    for (final text in texts) {
      result.addAll(_lettersFromText(text));
    }
    return _dedupeLetters(result);
  }

  static String _cleanAnswerText(String text) {
    return text
        .replaceAll(
          RegExp(r'^(正确答案|参考答案|我的答案|答案|ANSWER)[:：]?', caseSensitive: false),
          '',
        )
        .trim();
  }

  static bool _shouldSplitTextAnswer(String questionType) {
    return questionType.contains('填空') ||
        questionType.contains('分录') ||
        questionType.contains('连线');
  }

  static List<String> _splitTextAnswer(String text) {
    final separators = ['===', '###', '---', '|', '#', '\n', ';', '；'];
    for (final separator in separators) {
      final parts = text
          .split(separator)
          .map(_cleanSplitAnswerPart)
          .where((item) => item.isNotEmpty)
          .toList();
      if (parts.length > 1) {
        return parts;
      }
    }
    return [
      _cleanSplitAnswerPart(text),
    ].where((item) => item.isNotEmpty).toList();
  }

  static List<String> _splitClarkMarkedAnswer(String text) {
    final marker = RegExp(r'[\(（]\s*\d+\s*CLARK\s*[\)）]', caseSensitive: false);
    if (!marker.hasMatch(text)) {
      return const [];
    }

    final parts = text
        .split(marker)
        .map(_cleanSplitAnswerPart)
        .where((item) => item.isNotEmpty)
        .toList();
    return parts;
  }

  static String _cleanSplitAnswerPart(String text) {
    return text
        .replaceAll(RegExp(r'^第\s*[\d一二三四五六七八九十百]+\s*小题\s*[:：、，,.\s]*'), '')
        .trim();
  }

  static List<String> _stringsFromValue(Object? value) {
    if (value == null) {
      return const [];
    }
    if (value is List) {
      return [for (final item in value) ..._stringsFromValue(item)];
    }
    if (value is Map) {
      return _answerCandidates(value).expand(_stringsFromValue).toList();
    }

    final text = value.toString().trim();
    if (text.isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(text);
      if (decoded is List || decoded is Map) {
        return _stringsFromValue(decoded);
      }
    } catch (_) {
      // Plain answer text.
    }

    return [text];
  }

  static List<String> _lettersFromText(String text) {
    final normalized = _normalizeAnswerText(text)
        .replaceAll(
          RegExp(
            r'^(正确答案|我的答案|答案|选项|ANSWER|OPTION)[:：]?',
            caseSensitive: false,
          ),
          '',
        )
        .trim();
    final compactPattern = RegExp(
      r'^[A-H](?:\s*(?:[,，、;；|/\\\s]|和|与|及)*\s*[A-H])*$',
    );
    if (compactPattern.hasMatch(normalized)) {
      return _dedupeLetters(
        RegExp(r'[A-H]').allMatches(normalized).map((m) => m.group(0)!),
      );
    }

    final letters = <String>[];
    for (var i = 0; i < normalized.length; i++) {
      final char = normalized[i];
      if (!_isAnswerLetter(char)) {
        continue;
      }
      final previousIsLetter = i > 0 && _isEnglishLetter(normalized[i - 1]);
      final nextIsLetter =
          i + 1 < normalized.length && _isEnglishLetter(normalized[i + 1]);
      if (!previousIsLetter && !nextIsLetter) {
        letters.add(char);
      }
    }
    return _dedupeLetters(letters);
  }

  static List<String> _judgementLetters(Object? value, List<String> options) {
    final texts = _stringsFromValue(value);
    for (final text in texts) {
      final normalized = _normalizeJudgementText(text);
      final correct = _containsJudgementWord(normalized, _correctWords);
      final incorrect = _containsJudgementWord(normalized, _incorrectWords);
      if (correct == incorrect) {
        continue;
      }

      final letter = _findJudgementOption(correct, options);
      if (letter != null) {
        return [letter];
      }
    }
    return const [];
  }

  static String? _findJudgementOption(bool correct, List<String> options) {
    final words = correct ? _correctWords : _incorrectWords;
    for (var i = 0; i < options.length && i < 8; i++) {
      final text = _normalizeJudgementText(options[i]);
      if (_containsJudgementWord(text, words)) {
        return String.fromCharCode(65 + i);
      }
    }

    if (correct && options.isNotEmpty) {
      return 'A';
    }
    if (!correct && options.length > 1) {
      return 'B';
    }
    return null;
  }

  static bool _containsJudgementWord(String text, List<String> words) {
    return words.any((word) {
      final normalized = _normalizeJudgementText(word);
      if (normalized.length == 1 && RegExp(r'[A-Z0-9]').hasMatch(normalized)) {
        return text == normalized;
      }
      return text.contains(normalized);
    });
  }

  static String _normalizeAnswerText(String text) {
    return text
        .toUpperCase()
        .replaceAllMapped(
          RegExp(r'[Ａ-Ｈ]'),
          (m) => String.fromCharCode(m.group(0)!.codeUnitAt(0) - 65248),
        )
        .trim();
  }

  static String _normalizeJudgementText(String text) {
    return _normalizeAnswerText(text)
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[\.。、,，:：;；\[\]【】()（）]'), '');
  }

  static bool _isAnswerLetter(String char) {
    return char.length == 1 &&
        char.codeUnitAt(0) >= 65 &&
        char.codeUnitAt(0) <= 72;
  }

  static bool _isEnglishLetter(String char) {
    final code = char.codeUnitAt(0);
    return code >= 65 && code <= 90;
  }

  static List<String> _dedupeLetters(Iterable<String> letters) {
    final result = <String>[];
    final seen = <String>{};
    for (final letter in letters) {
      final normalized = _normalizeAnswerText(letter);
      if (_isAnswerLetter(normalized) && seen.add(normalized)) {
        result.add(normalized);
      }
    }
    return result;
  }

  static const _correctWords = ['正确', '对', '是', '√', 'TRUE', 'YES', 'T', '1'];

  static const _incorrectWords = [
    '错误',
    '错',
    '否',
    '非',
    '×',
    'X',
    'FALSE',
    'NO',
    'F',
    '0',
  ];

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
      } else if (q.answered) {
        final index = result.indexWhere(
          (item) => jsonEncode([item.type, item.content, item.options]) == key,
        );
        if (index != -1 && !result[index].answered) {
          result[index] = q;
        }
      }
    }
    return result;
  }

  static const String collectQuestionsJs =
      AppStrings.chaoxingCollectQuestionsJs;

  static const String answerJs = AppStrings.chaoxingAnswerJs;
}
