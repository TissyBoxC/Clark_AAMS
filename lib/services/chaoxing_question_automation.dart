import 'dart:convert';

import '../resources/app_strings.dart';

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

  static String? extractLetter(Object? aiResult) {
    if (aiResult == null) {
      return null;
    }

    String aiResultText;
    if (aiResult is Map) {
      final value =
          aiResult['answer'] ??
          aiResult[AppStrings.chaoxingAnswerKey] ??
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

  static const String collectQuestionsJs =
      AppStrings.chaoxingCollectQuestionsJs;

  static const String answerJs = AppStrings.chaoxingAnswerJs;
}
