import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../resources/app_colors.dart';
import '../resources/app_metrics.dart';
import '../resources/app_strings.dart';
import '../services/schedule_scope.dart';
import '../services/schedule_utils.dart';
import '../widgets/app_icons.dart';
import '../widgets/feedback.dart';
import '../widgets/soft_ui.dart';

/// 学期与作息设置：开学第一天、总周数、每节课开始时间。
///
/// 这些值一变，整张课表的"第几周""几点上课"会一起变，
/// 所以每次改动都即时写入本地存储，不做"全部保存"按钮。
class TermSetupPage extends StatefulWidget {
  const TermSetupPage({
    required this.initialStartTimes,
    required this.initialTermStartDate,
    required this.lessonCount,
    required this.profiles,
    required this.notice,
    super.key,
  });

  final List<String> initialStartTimes;
  final DateTime initialTermStartDate;
  final int lessonCount;
  final List<dynamic> profiles;
  final String notice;

  @override
  State<TermSetupPage> createState() => _TermSetupPageState();
}

class _TermSetupPageState extends State<TermSetupPage> {
  late DateTime _termStart;
  late List<String> _times;
  late int _maxWeeks;

  @override
  void initState() {
    super.initState();
    _termStart = widget.initialTermStartDate;
    _times = _fitTimes(widget.initialStartTimes, widget.lessonCount);
    _maxWeeks = ScheduleScope.of(context).settings.maxWeeks;
  }

  static List<String> _fitTimes(List<String> times, int count) {
    final result = [...times];
    while (result.length < count) {
      result.add('');
    }
    return result.take(count).toList();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _termStart,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: AppStrings.termFirstDayLabel,
    );
    if (picked != null && mounted) {
      setState(() => _termStart = picked);
    }
  }

  Future<void> _pickTime(int index) async {
    final current = minutesOfDay(_times[index]) ?? 8 * 60;
    final result = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
      helpText: AppStrings.selectLessonStartTime,
    );
    if (result == null || !mounted) {
      return;
    }
    setState(() {
      _times[index] = formatMinutes(result.hour * 60 + result.minute);
    });
  }

  Future<void> _save() async {
    final store = ScheduleScope.of(context);
    final settings = store.settings;
    final next = settings.copyWith(
      termStartDate: ScheduleUtils.formatDate(_termStart),
      termMonth: _termStart.month,
      termDay: _termStart.day,
      startTimes: _times,
      maxWeeks: _maxWeeks,
    );
    await store.updateSettings(next);
    if (mounted) {
      Navigator.of(context).pop();
      AppNotice.success(context, '学期与作息已保存');
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 760;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text(AppStrings.termAndLessonTimesTitle),
        leading: IconButton(
          icon: const Icon(AppIcons.close),
          tooltip: AppStrings.close,
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppMetrics.sp4),
            child: PrimaryButton(
              label: AppStrings.saveChanges,
              onPressed: _save,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppMetrics.sp5,
                AppMetrics.sp4,
                AppMetrics.sp5,
                AppMetrics.sp6,
              ),
              children: [
                const HintText(AppStrings.termAndLessonTimesSubtitle),
                const SizedBox(height: AppMetrics.sp4),
                SoftCard(
                  onTap: _pickDate,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              AppStrings.termFirstDayLabel,
                              style: TextStyle(
                                fontSize: AppMetrics.tiny,
                                color: AppColors.ink500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ScheduleUtils.formatDate(_termStart),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        AppIcons.chevronRight,
                        color: AppColors.ink400,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppMetrics.sp4),
                SoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CardHeading(
                        title: AppStrings.maxWeeksLabel,
                        subtitle: '一学期一共几周，决定周次条能翻到第几周。',
                      ),
                      const SizedBox(height: AppMetrics.sp3),
                      Slider(
                        value: _maxWeeks.toDouble(),
                        min: 1,
                        max: 30,
                        divisions: 29,
                        label: AppStrings.weekNumber(_maxWeeks),
                        onChanged: (value) =>
                            setState(() => _maxWeeks = value.round()),
                      ),
                      Text(
                        AppStrings.weekNumber(_maxWeeks),
                        style: const TextStyle(
                          fontSize: AppMetrics.small,
                          color: AppColors.ink600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppMetrics.sp4),
                SoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const CardHeading(
                        title: AppStrings.lessonStartTimesLabel,
                        subtitle: AppStrings.lessonStartTimesHelp,
                      ),
                      const SizedBox(height: AppMetrics.sp3),
                      for (var index = 0; index < _times.length; index++)
                        _TimeRow(
                          index: index,
                          value: _times[index],
                          onTap: () => _pickTime(index),
                        ),
                      if (widget.notice.isNotEmpty) ...[
                        const SizedBox(height: AppMetrics.sp3),
                        HintText(widget.notice),
                      ],
                    ],
                  ),
                ),
                if (wide) const SizedBox(height: AppMetrics.sp4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.index,
    required this.value,
    required this.onTap,
  });

  final int index;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final configured = value.trim().isNotEmpty;
    return InkWell(
      borderRadius: BorderRadius.circular(AppMetrics.rMd),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 88,
              child: Text(
                AppStrings.lessonPickerText(index + 1),
                style: const TextStyle(
                  fontSize: AppMetrics.small,
                  color: AppColors.ink700,
                ),
              ),
            ),
            Expanded(
              child: Text(
                configured ? value : AppStrings.notConfigured,
                style: TextStyle(
                  fontSize: AppMetrics.small,
                  fontWeight: configured ? FontWeight.w500 : FontWeight.w400,
                  color: configured ? AppColors.ink900 : AppColors.ink400,
                ),
              ),
            ),
            const Icon(
              AppIcons.chevronRight,
              size: 18,
              color: AppColors.ink400,
            ),
          ],
        ),
      ),
    );
  }
}

/// 旧的设置页入口保留一个薄壳，避免别处引用失效。
class AppSettingsPage extends StatelessWidget {
  const AppSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

/// 设置项的默认值展示（供课程管理页复用）。
String describeSettings(AppSettingsModel settings) {
  final date = settings.termStartDate.isEmpty
      ? AppStrings.notSet
      : settings.termStartDate;
  return '${AppStrings.termFirstDayLabel}：$date';
}
