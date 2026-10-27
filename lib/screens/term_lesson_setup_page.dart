import 'package:flutter/material.dart';

import '../models/school_lesson_times.dart';
import '../resources/app_strings.dart';
import '../services/schedule_utils.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/top_bar.dart';

class TermLessonSetupResult {
  const TermLessonSetupResult({
    required this.termStartDate,
    required this.startTimes,
  });

  final DateTime termStartDate;
  final List<String> startTimes;
}

class TermLessonSetupPage extends StatefulWidget {
  const TermLessonSetupPage({
    super.key,
    required this.initialTermStartDate,
    required this.initialStartTimes,
    required this.lessonCount,
    this.title = AppStrings.setupTermAndLessonTimeTitle,
    this.subtitle = AppStrings.setupTermAndLessonTimeSubtitle,
    this.confirmText = AppStrings.saveConfig,
    this.cancelText = AppStrings.cancel,
    this.lessonTimeProfiles = const <SchoolLessonTimes>[],
    this.lessonTimeNotice = '',
  });

  final DateTime initialTermStartDate;
  final List<String> initialStartTimes;
  final int lessonCount;
  final String title;
  final String subtitle;
  final String confirmText;
  final String cancelText;
  final List<SchoolLessonTimes> lessonTimeProfiles;
  final String lessonTimeNotice;

  @override
  State<TermLessonSetupPage> createState() => _TermLessonSetupPageState();
}

class _TermLessonSetupPageState extends State<TermLessonSetupPage> {
  late DateTime _termStartDate;
  late final List<String> _startTimes;

  @override
  void initState() {
    super.initState();
    _termStartDate = widget.initialTermStartDate;
    _startTimes = [
      for (var index = 0; index < widget.lessonCount; index++)
        index < widget.initialStartTimes.length
            ? widget.initialStartTimes[index]
            : '',
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfffff9fa),
      body: Column(
        children: [
          TopBar(
            title: AppStrings.timeConfigTitle,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xff4a2e3b),
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1.18,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xff6b4f5a),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 28),
                _SetupPanel(
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xffeef0ff),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.event_rounded,
                          color: Color(0xffc93c7d),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              AppStrings.termFirstDayLabel,
                              style: TextStyle(
                                color: Color(0xff4a2e3b),
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ScheduleUtils.localDateLabel(_termStartDate),
                              style: const TextStyle(
                                color: Color(0xff6b4f5a),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _pickTermStartDate,
                        child: const Text(AppStrings.select),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _SetupPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        AppStrings.lessonStartTimesLabel,
                        style: TextStyle(
                          color: Color(0xff4a2e3b),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (widget.lessonTimeNotice.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          widget.lessonTimeNotice,
                          style: const TextStyle(
                            color: Color(0xffc93c7d),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            height: 1.35,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      const Text(
                        AppStrings.lessonStartTimesHelp,
                        style: TextStyle(
                          color: Color(0xff6b4f5a),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                      if (widget.lessonTimeProfiles.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        for (final profile in widget.lessonTimeProfiles)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _LessonTimeProfileButton(
                              profile: profile,
                              onTap: () => _applyLessonTimeProfile(profile),
                            ),
                          ),
                      ],
                      const SizedBox(height: 14),
                      for (var index = 0; index < _startTimes.length; index++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Material(
                            color: const Color(0xfff7f5ff),
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _pickLessonTime(index),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 13,
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 76,
                                      child: Text(
                                        AppStrings.lessonNumberWithSpaces(
                                          index + 1,
                                        ),
                                        style: const TextStyle(
                                          color: Color(0xff4a2e3b),
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        _startTimes[index].isEmpty
                                            ? AppStrings.notConfigured
                                            : _startTimes[index],
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          color: _startTimes[index].isEmpty
                                              ? const Color(0xffaaa4b8)
                                              : const Color(0xff4a2e3b),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.unfold_more_rounded,
                                      color: Color(0xff6b4f5a),
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(widget.cancelText),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _save,
                      child: Text(widget.confirmText),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickTermStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _termStartDate,
      firstDate: DateTime(_termStartDate.year - 2),
      lastDate: DateTime(_termStartDate.year + 2),
      helpText: AppStrings.selectFirstWeekFirstDayTitle,
      cancelText: AppStrings.cancel,
      confirmText: AppStrings.confirm,
    );
    if (picked == null) {
      return;
    }
    setState(() => _termStartDate = picked);
  }

  void _save() {
    final times = [..._startTimes];
    while (times.isNotEmpty && times.last.isEmpty) {
      times.removeLast();
    }
    Navigator.of(context).pop(
      TermLessonSetupResult(termStartDate: _termStartDate, startTimes: times),
    );
  }

  void _applyLessonTimeProfile(SchoolLessonTimes profile) {
    final times = profile.toStartTimes(minimumLength: _startTimes.length);
    setState(() {
      for (var index = 0; index < _startTimes.length; index++) {
        _startTimes[index] = index < times.length ? times[index] : '';
      }
    });
    final start = profile.firstConfiguredStartTime;
    AppSnackBar.show(
      context,
      start.isEmpty
          ? AppStrings.generalLessonTimesImported
          : AppStrings.lessonTimesImportedForStart(start),
    );
  }

  Future<void> _pickLessonTime(int lessonIndex) async {
    final current = _startTimes[lessonIndex];
    final parsed = _parseTime(current);
    var selectedPeriod = parsed.period;
    var selectedHour = parsed.hour;
    var selectedMinute = parsed.minute;
    final periodController = FixedExtentScrollController(
      initialItem: selectedPeriod,
    );
    final hourController = FixedExtentScrollController(
      initialItem: selectedHour - 1,
    );
    final minuteController = FixedExtentScrollController(
      initialItem: selectedMinute,
    );
    final result = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: SizedBox(
                height: 330,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 2, 20, 10),
                      child: Row(
                        children: [
                          Text(
                            AppStrings.selectLessonStartTime(lessonIndex + 1),
                            style: const TextStyle(
                              color: Color(0xff4a2e3b),
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(''),
                            child: const Text(AppStrings.notConfigured),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(
                              _formatPickedTime(
                                selectedPeriod,
                                selectedHour,
                                selectedMinute,
                              ),
                            ),
                            child: const Text(AppStrings.confirm),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            height: 44,
                            margin: const EdgeInsets.symmetric(horizontal: 18),
                            decoration: BoxDecoration(
                              color: const Color(0xfffff2f5),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xfff7d9e2),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: _WheelColumn(
                                  controller: periodController,
                                  itemCount: 2,
                                  selectedIndex: selectedPeriod,
                                  labelFor: (index) => index == 0
                                      ? AppStrings.morning
                                      : AppStrings.afternoon,
                                  onChanged: (value) {
                                    setSheetState(() => selectedPeriod = value);
                                  },
                                ),
                              ),
                              Expanded(
                                child: _WheelColumn(
                                  controller: hourController,
                                  itemCount: 12,
                                  selectedIndex: selectedHour - 1,
                                  labelFor: (index) =>
                                      '${index + 1}'.padLeft(2, '0'),
                                  onChanged: (value) {
                                    setSheetState(
                                      () => selectedHour = value + 1,
                                    );
                                  },
                                ),
                              ),
                              Expanded(
                                child: _WheelColumn(
                                  controller: minuteController,
                                  itemCount: 60,
                                  selectedIndex: selectedMinute,
                                  labelFor: (index) => '$index'.padLeft(2, '0'),
                                  onChanged: (value) {
                                    setSheetState(() => selectedMinute = value);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Center(
                              child: Text(
                                AppStrings.period,
                                style: TextStyle(
                                  color: Color(0xff6b4f5a),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                AppStrings.hour,
                                style: TextStyle(
                                  color: Color(0xff6b4f5a),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                AppStrings.minute,
                                style: TextStyle(
                                  color: Color(0xff6b4f5a),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    periodController.dispose();
    hourController.dispose();
    minuteController.dispose();
    if (result == null) {
      return;
    }
    setState(() => _startTimes[lessonIndex] = result);
  }

  _PickedTime _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length != 2) {
      return const _PickedTime(period: 0, hour: 8, minute: 0);
    }
    final rawHour = int.tryParse(parts[0]) ?? 8;
    final minute = (int.tryParse(parts[1]) ?? 0).clamp(0, 59);
    final period = rawHour >= 12 ? 1 : 0;
    var hour = rawHour % 12;
    if (hour == 0) {
      hour = 12;
    }
    return _PickedTime(period: period, hour: hour, minute: minute);
  }

  String _formatPickedTime(int period, int hour, int minute) {
    var value = hour % 12;
    if (period == 1) {
      value += 12;
    }
    return '${value.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}

class _LessonTimeProfileButton extends StatelessWidget {
  const _LessonTimeProfileButton({required this.profile, required this.onTap});

  final SchoolLessonTimes profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final start = profile.firstConfiguredStartTime;
    final title = start.isEmpty
        ? AppStrings.importGeneralLessonTimes
        : AppStrings.importLessonTimesForStart(start);
    final subtitle = start.isEmpty
        ? AppStrings.generalLessonTimesDescription
        : AppStrings.lessonTimesDescription(_trimLeadingZero(start));
    return Material(
      color: const Color(0xfffff2f5),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.download_done_rounded, color: Color(0xffc93c7d)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xff4a2e3b),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xff6b4f5a),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xff6b4f5a)),
            ],
          ),
        ),
      ),
    );
  }

  static String _trimLeadingZero(String value) {
    if (value.startsWith('0')) {
      return value.substring(1);
    }
    return value;
  }
}

class _PickedTime {
  const _PickedTime({
    required this.period,
    required this.hour,
    required this.minute,
  });

  final int period;
  final int hour;
  final int minute;
}

class _WheelColumn extends StatelessWidget {
  const _WheelColumn({
    required this.controller,
    required this.itemCount,
    required this.selectedIndex,
    required this.labelFor,
    required this.onChanged,
  });

  final FixedExtentScrollController controller;
  final int itemCount;
  final int selectedIndex;
  final String Function(int index) labelFor;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: 44,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: onChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: itemCount,
        builder: (context, index) {
          final selected = index == selectedIndex;
          return Center(
            child: Text(
              labelFor(index),
              style: TextStyle(
                color: selected
                    ? const Color(0xffc93c7d)
                    : const Color(0xffb0aabd),
                fontSize: selected ? 24 : 19,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SetupPanel extends StatelessWidget {
  const _SetupPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xffeeeaff)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140b0550),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}
