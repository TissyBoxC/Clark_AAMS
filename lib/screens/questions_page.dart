import 'dart:convert';

import 'package:flutter/material.dart';

import '../resources/app_colors.dart';
import '../resources/app_metrics.dart';
import '../resources/app_strings.dart';
import '../services/clark_backend_api.dart';
import '../widgets/app_icons.dart';
import '../widgets/feedback.dart';
import '../widgets/soft_ui.dart';
import 'import_page.dart' show SegmentedTabs;

/// 题目解析。
///
/// 两种题型分开填：选择题要选项，主观题可以带材料和参考答案。
/// 结果只展示"答案"和"解题思路"两段，不把服务返回的结构直接摊给用户看。
class QuestionsPage extends StatefulWidget {
  const QuestionsPage({super.key});

  @override
  State<QuestionsPage> createState() => _QuestionsPageState();
}

class _QuestionsPageState extends State<QuestionsPage> {
  final _content = TextEditingController();
  final _material = TextEditingController();
  final _reference = TextEditingController();
  final _mine = TextEditingController();
  final List<TextEditingController> _options = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  bool _choice = true;
  bool _running = false;
  String _error = '';
  String _answer = '';
  String _analysis = '';

  @override
  void dispose() {
    _content.dispose();
    _material.dispose();
    _reference.dispose();
    _mine.dispose();
    for (final option in _options) {
      option.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final content = _content.text.trim();
    if (content.length < 4) {
      setState(() => _error = '把题目完整贴进来，太短的片段读不出考点。');
      return;
    }

    setState(() {
      _running = true;
      _error = '';
      _answer = '';
      _analysis = '';
    });

    try {
      if (_choice) {
        final options = _options
            .map((controller) => controller.text.trim())
            .where((value) => value.isNotEmpty)
            .toList();
        if (options.length < 2) {
          setState(() {
            _error = '选择题至少要有两个选项。';
            _running = false;
          });
          return;
        }
        final result = await ClarkBackendApi.instance.analyzeQuestion(
          questionType: 'single_choice',
          questionContent: content,
          options: options,
        );
        _applyResult(result);
      } else {
        final result = await ClarkBackendApi.instance.analyzeFillBlankQuestion(
          questionType: 'fill_blank',
          questionContent: content,
          material: _material.text.trim(),
          referenceAnswer: _reference.text.trim(),
          studentAnswer: _mine.text.trim(),
        );
        _applyResult(result);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error is ApiException
              ? error.message
              : AppStrings.invalidQuestionAnalysisResponse;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _running = false);
      }
    }
  }

  /// 从结果里取出答案与解析。
  ///
  /// 服务返回的字段名可能变化，这里按几种常见写法兜底，
  /// 实在读不出来就只显示「换个说法再试」，不让用户看到原始结构。
  void _applyResult(Map<String, Object?> result) {
    String pick(List<String> keys) {
      for (final key in keys) {
        final value = result[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
      return '';
    }

    final answer = pick(['answer', 'correctAnswer', 'result']);
    var analysis = pick(['analysis', 'explanation', 'reasoning', 'solution']);
    if (analysis.isEmpty && result['analysis'] is Map) {
      analysis = const JsonEncoder.withIndent('  ').convert(result['analysis']);
    }

    setState(() {
      _answer = answer;
      _analysis = analysis;
    });
  }

  void _reset() {
    _content.clear();
    _material.clear();
    _reference.clear();
    _mine.clear();
    for (final option in _options) {
      option.clear();
    }
    setState(() {
      _answer = '';
      _analysis = '';
      _error = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: AppStrings.questionsTitle,
      description: AppStrings.questionsSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedTabs(
            value: _choice ? 'choice' : 'open',
            items: const [
              ('choice', AppStrings.choiceQuestion),
              ('open', AppStrings.openQuestion),
            ],
            onChanged: (value) => setState(() {
              _choice = value == 'choice';
              _answer = '';
              _analysis = '';
            }),
          ),
          const SizedBox(height: AppMetrics.sp4),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _content,
                  minLines: 3,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: AppStrings.questionContentLabel,
                    hintText: AppStrings.questionContentHint,
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: AppMetrics.sp3),
                if (_choice) ...[
                  const CardHeading(title: AppStrings.questionOptionsLabel),
                  const SizedBox(height: AppMetrics.sp3),
                  for (var index = 0; index < _options.length; index++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppMetrics.sp2),
                      child: TextField(
                        controller: _options[index],
                        decoration: InputDecoration(
                          labelText: '选项 ${String.fromCharCode(65 + index)}',
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      if (_options.length < 6)
                        QuietButton(
                          label: AppStrings.addOption,
                          icon: AppIcons.plus,
                          onPressed: () => setState(
                            () => _options.add(TextEditingController()),
                          ),
                        ),
                      const SizedBox(width: AppMetrics.sp2),
                      if (_options.length > 2)
                        QuietButton(
                          label: AppStrings.dropOption,
                          onPressed: () => setState(() {
                            _options.removeLast().dispose();
                          }),
                        ),
                    ],
                  ),
                ] else ...[
                  TextField(
                    controller: _material,
                    minLines: 2,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: AppStrings.questionMaterialLabel,
                      hintText: AppStrings.questionMaterialHint,
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: AppMetrics.sp3),
                  TextField(
                    controller: _reference,
                    decoration: const InputDecoration(
                      labelText: AppStrings.questionReferenceLabel,
                      hintText: AppStrings.questionReferenceHint,
                    ),
                  ),
                  const SizedBox(height: AppMetrics.sp3),
                  TextField(
                    controller: _mine,
                    decoration: const InputDecoration(
                      labelText: AppStrings.questionMineLabel,
                      hintText: AppStrings.questionMineHint,
                    ),
                  ),
                ],
                if (_error.isNotEmpty) ...[
                  const SizedBox(height: AppMetrics.sp3),
                  NoticeBar(message: _error, tone: NoticeTone.error),
                ],
                const SizedBox(height: AppMetrics.sp4),
                Row(
                  children: [
                    PrimaryButton(
                      label: _running
                          ? AppStrings.analyzing
                          : AppStrings.startAnalysis,
                      loading: _running,
                      onPressed: _submit,
                    ),
                    const SizedBox(width: AppMetrics.sp2),
                    QuietButton(
                      label: AppStrings.clearAndRewrite,
                      onPressed: _reset,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_answer.isNotEmpty || _analysis.isNotEmpty) ...[
            const SizedBox(height: AppMetrics.sp4),
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const CardHeading(title: AppStrings.analysisResult),
                  if (_answer.isNotEmpty) ...[
                    const SizedBox(height: AppMetrics.sp4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppMetrics.sp4,
                        vertical: AppMetrics.sp3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brand050,
                        borderRadius: BorderRadius.circular(AppMetrics.rLg),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            AppStrings.answerLabel,
                            style: TextStyle(
                              fontSize: AppMetrics.tiny,
                              color: AppColors.ink500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            _answer,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: AppColors.brand700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_analysis.isNotEmpty) ...[
                    const SizedBox(height: AppMetrics.sp4),
                    const Text(
                      AppStrings.analysisLabel,
                      style: TextStyle(
                        fontSize: AppMetrics.small,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink900,
                      ),
                    ),
                    const SizedBox(height: AppMetrics.sp2),
                    SelectableText(
                      _analysis,
                      style: const TextStyle(
                        fontSize: AppMetrics.body,
                        height: 1.9,
                        color: AppColors.ink600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: AppMetrics.sp4),
          const SoftCard(
            sunken: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '解析能做到什么',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink900,
                  ),
                ),
                SizedBox(height: AppMetrics.sp2),
                HintText(
                  '它给的是思路和步骤，不是保证正确的标准答案。'
                  '涉及图表、专业符号特别多的题目，解析可能不完整，最后还是以课本和老师讲解为准。',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
