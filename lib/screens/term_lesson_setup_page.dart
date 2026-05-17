import 'package:flutter/material.dart';

import '../models/school_lesson_times.dart';
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
    this.title = '设置学期与上课时间',
    this.subtitle = '先选择第一周第一天，再按需配置每节课开始时间',
    this.confirmText = '保存配置',
    this.cancelText = '取消',
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
      backgroundColor: const Color(0xfffffbff),
      body: Column(
        children: [
          TopBar(
            title: '时间配置',
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
                    color: Color(0xff1f1b2d),
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
                    color: Color(0xff8a8498),
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
                          color: Color(0xff6d64ff),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '第一周第一天',
                              style: TextStyle(
                                color: Color(0xff1f1b2d),
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ScheduleUtils.localDateLabel(_termStartDate),
                              style: const TextStyle(
                                color: Color(0xff8a8498),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _pickTermStartDate,
                        child: const Text('选择'),
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
                        '每节课开始时间',
                        style: TextStyle(
                          color: Color(0xff1f1b2d),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (widget.lessonTimeNotice.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          widget.lessonTimeNotice,
                          style: const TextStyle(
                            color: Color(0xff6d64ff),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            height: 1.35,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      const Text(
                        '可留空。导入作息只会帮你填入数据，保存前仍可逐节修改；留空时课程表正常显示，但桌面小组件不会显示上课时间，也无法按当前时间判断下一节课。',
                        style: TextStyle(
                          color: Color(0xff8a8498),
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
                                        '第 ${index + 1} 节',
                                        style: const TextStyle(
                                          color: Color(0xff1f1b2d),
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        _startTimes[index].isEmpty
                                            ? '未配置'
                                            : _startTimes[index],
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          color: _startTimes[index].isEmpty
                                              ? const Color(0xffaaa4b8)
                                              : const Color(0xff1f1b2d),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.unfold_more_rounded,
                                      color: Color(0xff8a8498),
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
      helpText: '选择第一周第一天',
      cancelText: '取消',
      confirmText: '确定',
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
      start.isEmpty ? '已导入通用作息，可继续逐节修改' : '已导入$start上课作息，可继续逐节修改',
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
                            '第 ${lessonIndex + 1} 节开始时间',
                            style: const TextStyle(
                              color: Color(0xff1f1b2d),
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(''),
                            child: const Text('未配置'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(
                              _formatPickedTime(
                                selectedPeriod,
                                selectedHour,
                                selectedMinute,
                              ),
                            ),
                            child: const Text('确定'),
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
                              color: const Color(0xfff1eeff),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xffd8d0ff),
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
                                  labelFor: (index) => index == 0 ? '上午' : '下午',
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
                                '时段',
                                style: TextStyle(
                                  color: Color(0xff8a8498),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                '小时',
                                style: TextStyle(
                                  color: Color(0xff8a8498),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                '分钟',
                                style: TextStyle(
                                  color: Color(0xff8a8498),
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
    final title = start.isEmpty ? '导入通用作息' : '导入 $start 上课作息';
    final subtitle = start.isEmpty
        ? '这套为通用配置'
        : '这套为${_trimLeadingZero(start)}上课';
    return Material(
      color: const Color(0xfff1eeff),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.download_done_rounded, color: Color(0xff6d64ff)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xff1f1b2d),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xff8a8498),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xff8a8498)),
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
                    ? const Color(0xff6d64ff)
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
