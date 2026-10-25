import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../resources/app_strings.dart';
import '../services/auth_session.dart';
import '../services/chaoxing_question_automation.dart';
import '../services/clark_backend_api.dart';
import '../widgets/app_snack_bar.dart';

class ChaoxingHomeworkPage extends StatefulWidget {
  const ChaoxingHomeworkPage({super.key});

  @override
  State<ChaoxingHomeworkPage> createState() => _ChaoxingHomeworkPageState();
}

class _ChaoxingHomeworkPageState extends State<ChaoxingHomeworkPage> {
  late final WebViewController _controller;

  bool _loading = true;
  bool _answering = false;
  bool _stopRequested = false;
  bool _panelCollapsed = false;
  Offset _panelOffset = const Offset(16, 86);

  String _currentUrl = 'https://i.chaoxing.com/';
  String _currentTitle = AppStrings.chaoxingHomeTitle;
  String _status = AppStrings.chaoxingInitialStatus;
  String _controlledPage = 'https://i.chaoxing.com/';
  int _foundCount = 0;
  int _currentIndex = 0;
  int _successCount = 0;
  int _failedCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            _setLoading(true);
            setState(() {
              _currentUrl = url;
              _controlledPage = url;
              if (!_answering) {
                _status = AppStrings.chaoxingPageLoading;
              }
            });
          },
          onPageFinished: (url) async {
            _setLoading(false);
            _currentUrl = url;
            await _refreshPageIdentity();
            if (mounted && !_answering) {
              setState(() => _status = AppStrings.chaoxingEnterHomeworkPage);
            }
          },
          onWebResourceError: (error) {
            if (!mounted || error.isForMainFrame != true) {
              return;
            }
            setState(() {
              _loading = false;
              _status = AppStrings.chaoxingPageLoadFailed(error.description);
            });
          },
        ),
      )
      ..loadRequest(Uri.parse('https://i.chaoxing.com/'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.chaoxingTitle),
        actions: [
          IconButton(
            tooltip: AppStrings.chaoxingReload,
            onPressed: _answering ? null : _controller.reload,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: AppStrings.chaoxingBackHome,
            onPressed: _answering
                ? null
                : () => _controller.loadRequest(
                    Uri.parse('https://i.chaoxing.com/'),
                  ),
            icon: const Icon(Icons.home_outlined),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final panelWidth = constraints.maxWidth < 420
              ? constraints.maxWidth - 32
              : 360.0;
          final left = _panelOffset.dx.clamp(
            8.0,
            (constraints.maxWidth - panelWidth - 8).clamp(8.0, double.infinity),
          );
          final top = _panelOffset.dy.clamp(
            8.0,
            (constraints.maxHeight - 92).clamp(8.0, double.infinity),
          );

          return Stack(
            children: [
              WebViewWidget(controller: _controller),
              if (_loading)
                const Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              Positioned(
                left: left,
                top: top,
                width: panelWidth,
                child: _FloatingAutomationPanel(
                  collapsed: _panelCollapsed,
                  answering: _answering,
                  status: _status,
                  currentTitle: _currentTitle,
                  controlledPage: _controlledPage,
                  foundCount: _foundCount,
                  currentIndex: _currentIndex,
                  successCount: _successCount,
                  failedCount: _failedCount,
                  onStart: _startAnswering,
                  onStop: _requestStop,
                  onToggleCollapsed: () {
                    setState(() => _panelCollapsed = !_panelCollapsed);
                  },
                  onPanUpdate: (details) {
                    setState(() => _panelOffset += details.delta);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _setLoading(bool value) {
    if (!mounted) {
      return;
    }
    setState(() => _loading = value);
  }

  Future<void> _refreshPageIdentity() async {
    final url = await _controller.currentUrl();
    String title = '';
    try {
      final result = await _controller.runJavaScriptReturningResult(
        'document.title || location.href',
      );
      title = _decodeJavaScriptString(result);
    } catch (_) {
      title = '';
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _currentUrl = url ?? _currentUrl;
      _controlledPage = _currentUrl;
      _currentTitle = title.trim().isEmpty ? _currentUrl : title.trim();
    });
  }

  Future<void> _startAnswering() async {
    if (_answering) {
      return;
    }
    final hasCredential = await AuthSession.instance.hasUsableCredential();
    if (!hasCredential) {
      if (!mounted) {
        return;
      }
      setState(() => _status = AppStrings.chaoxingLoginRequired);
      AppSnackBar.show(context, AppStrings.chaoxingLoginRequired);
      return;
    }
    setState(() {
      _answering = true;
      _stopRequested = false;
      _foundCount = 0;
      _currentIndex = 0;
      _successCount = 0;
      _failedCount = 0;
      _status = AppStrings.chaoxingReadingPage;
    });

    try {
      await _refreshPageIdentity();
      await Future<void>.delayed(const Duration(milliseconds: 500));
      final questionsResult = await _controller.runJavaScriptReturningResult(
        ChaoxingQuestionAutomation.collectQuestionsJs,
      );
      final questions = ChaoxingQuestionAutomation.parseQuestions(
        questionsResult,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _foundCount = questions.length;
        _status = questions.isEmpty
            ? AppStrings.chaoxingNoQuestions
            : AppStrings.chaoxingFoundQuestions(questions.length);
      });

      for (var i = 0; i < questions.length; i++) {
        if (_stopRequested) {
          break;
        }

        final question = questions[i];
        setState(() {
          _currentIndex = i + 1;
          _status = AppStrings.chaoxingProcessingQuestion(question.number);
        });

        if (question.answered) {
          _successCount++;
          setState(
            () => _status = AppStrings.chaoxingQuestionSkipped(question.number),
          );
          continue;
        }

        try {
          final isChoiceQuestion = ChaoxingQuestionAutomation.isChoiceQuestion(
            question,
          );
          final aiResult = isChoiceQuestion
              ? await ClarkBackendApi.instance.analyzeQuestion(
                  questionType: question.type,
                  questionContent: question.content,
                  options: question.options,
                )
              : await ClarkBackendApi.instance.analyzeFillBlankQuestion(
                  questionType: question.type,
                  questionContent: question.content,
                );
          final letters = isChoiceQuestion
              ? ChaoxingQuestionAutomation.extractLetters(
                  aiResult,
                  questionType: question.type,
                  options: question.options,
                )
              : const <String>[];
          final textAnswers = isChoiceQuestion
              ? const <String>[]
              : ChaoxingQuestionAutomation.extractTextAnswers(
                  aiResult,
                  questionType: question.type,
                );
          if (letters.isEmpty && textAnswers.isEmpty) {
            _failedCount++;
            setState(
              () => _status = AppStrings.chaoxingNoAnswer(question.number),
            );
            continue;
          }

          final clickResult = await _controller.runJavaScriptReturningResult(
            ChaoxingQuestionAutomation.answerQuestionScript(
              question.number,
              letters: letters,
              textAnswers: textAnswers,
              questionType: question.type,
            ),
          );
          final answerResult =
              ChaoxingQuestionAutomation.parseAnswerClickResult(clickResult);
          if (answerResult.success) {
            _successCount++;
          } else {
            _failedCount++;
          }
        } on TimeoutException {
          _failedCount++;
          setState(
            () => _status = AppStrings.chaoxingQuestionTimeout(question.number),
          );
          continue;
        } on ApiException catch (error) {
          _failedCount++;
          if (error.code == 40101) {
            setState(() => _status = AppStrings.chaoxingLoginInvalid);
            break;
          }
          setState(
            () => _status = AppStrings.chaoxingQuestionFailed(question.number),
          );
          continue;
        } catch (error) {
          _failedCount++;
          setState(
            () => _status = AppStrings.chaoxingQuestionFailed(question.number),
          );
          continue;
        }

        await Future<void>.delayed(const Duration(milliseconds: 300));
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _status = _stopRequested
            ? AppStrings.chaoxingStopped(_successCount, _failedCount)
            : AppStrings.chaoxingCompleted(_successCount, _failedCount);
      });
    } catch (error) {
      if (mounted) {
        setState(() => _status = AppStrings.chaoxingAutomationError(error));
      }
    } finally {
      if (mounted) {
        setState(() {
          _answering = false;
          _stopRequested = false;
        });
      }
    }
  }

  void _requestStop() {
    if (!_answering) {
      return;
    }
    setState(() {
      _stopRequested = true;
      _status = AppStrings.chaoxingStopping;
    });
  }

  String _decodeJavaScriptString(Object? value) {
    if (value == null) {
      return '';
    }
    final text = value.toString();
    if (text == 'null' || text == 'undefined') {
      return '';
    }
    try {
      final decoded = jsonDecode(text);
      if (decoded is String) {
        return decoded;
      }
    } catch (_) {
      // Some platforms already return the raw JavaScript string.
    }
    return text;
  }
}

class _FloatingAutomationPanel extends StatelessWidget {
  const _FloatingAutomationPanel({
    required this.collapsed,
    required this.answering,
    required this.status,
    required this.currentTitle,
    required this.controlledPage,
    required this.foundCount,
    required this.currentIndex,
    required this.successCount,
    required this.failedCount,
    required this.onStart,
    required this.onStop,
    required this.onToggleCollapsed,
    required this.onPanUpdate,
  });

  final bool collapsed;
  final bool answering;
  final String status;
  final String currentTitle;
  final String controlledPage;
  final int foundCount;
  final int currentIndex;
  final int successCount;
  final int failedCount;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onToggleCollapsed;
  final GestureDragUpdateCallback onPanUpdate;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onPanUpdate: onPanUpdate,
      child: Material(
        elevation: 10,
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: collapsed ? _buildCollapsed(colorScheme) : _buildFull(context),
        ),
      ),
    );
  }

  Widget _buildCollapsed(ColorScheme colorScheme) {
    return InkWell(
      onTap: onToggleCollapsed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              answering ? Icons.play_circle : Icons.open_in_browser,
              size: 18,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                answering
                    ? AppStrings.chaoxingCollapsedProgress(
                        currentIndex,
                        foundCount,
                      )
                    : AppStrings.chaoxingCollapsedIdle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFull(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.open_in_browser, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  AppStrings.chaoxingPanelTitle,
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: AppStrings.chaoxingCollapsePanel,
                onPressed: onToggleCollapsed,
                icon: const Icon(Icons.expand_less),
              ),
            ],
          ),
          _InfoLine(
            label: AppStrings.chaoxingPageTitleLabel,
            value: currentTitle,
          ),
          _InfoLine(label: AppStrings.chaoxingUrlLabel, value: controlledPage),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _Metric(
                label: AppStrings.chaoxingFoundMetric,
                value: '$foundCount',
              ),
              _Metric(
                label: AppStrings.chaoxingCurrentMetric,
                value: foundCount == 0 ? '0' : '$currentIndex',
              ),
              _Metric(
                label: AppStrings.chaoxingSuccessMetric,
                value: '$successCount',
              ),
              _Metric(
                label: AppStrings.chaoxingFailedMetric,
                value: '$failedCount',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            status,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: Color(0xff4b5563)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: answering ? null : onStart,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text(AppStrings.chaoxingStart),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: answering ? onStop : null,
                icon: const Icon(Icons.stop),
                label: const Text(AppStrings.chaoxingStop),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 58,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xff6b7280)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xffeef7f5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label $value',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}
