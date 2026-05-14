import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/schedule_scope.dart';
import '../services/schedule_utils.dart';
import '../widgets/top_bar.dart';

class AppSettingsPage extends StatefulWidget {
  const AppSettingsPage({super.key});

  @override
  State<AppSettingsPage> createState() => _AppSettingsPageState();
}

class _AppSettingsPageState extends State<AppSettingsPage> {
  late TextEditingController _maxWeeksController;
  late TextEditingController _durationController;
  late TextEditingController _reminderController;
  late TextEditingController _startTimesController;
  bool _controllersReady = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controllersReady) {
      return;
    }
    final settings = ScheduleScope.of(context).settings;
    _maxWeeksController = TextEditingController(text: '${settings.maxWeeks}');
    _durationController = TextEditingController(
      text: '${settings.durationPerLesson}',
    );
    _reminderController = TextEditingController(
      text: '${settings.reminderTime}',
    );
    _startTimesController = TextEditingController(
      text: settings.startTimes.join('\n'),
    );
    _controllersReady = true;
  }

  @override
  void dispose() {
    if (_controllersReady) {
      _maxWeeksController.dispose();
      _durationController.dispose();
      _reminderController.dispose();
      _startTimesController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ScheduleScope.of(context);
    final settings = store.settings;

    return Scaffold(
      body: Column(
        children: [
          TopBar(
            title: '应用设置',
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              children: [
                _SettingRow(
                  label: '第一周第一天',
                  trailing: TextButton(
                    onPressed: _pickTermStartDate,
                    child: Text(
                      ScheduleUtils.localDateLabel(
                        ScheduleUtils.termStartDate(settings),
                      ),
                    ),
                  ),
                ),
                _SettingRow(
                  label: '最大周数',
                  trailing: _NumberField(
                    controller: _maxWeeksController,
                    width: 140,
                    onSubmitted: (_) => _saveMaxWeeks(),
                  ),
                ),
                _SettingRow(
                  label: '每节课时长',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _NumberField(
                        controller: _durationController,
                        width: 120,
                        onSubmitted: (_) => _saveDuration(),
                      ),
                      const Text('分钟', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
                _SettingRow(
                  label: '提前提醒',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _NumberField(
                        controller: _reminderController,
                        width: 120,
                        onSubmitted: (_) => _saveReminderTime(),
                      ),
                      const Text('分钟', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
                _SettingRow(
                  label: '提醒方式',
                  trailing: DropdownButton<int>(
                    value: settings.remindWay.clamp(
                      0,
                      ScheduleUtils.remindWays.length - 1,
                    ),
                    items: [
                      for (
                        var index = 0;
                        index < ScheduleUtils.remindWays.length;
                        index++
                      )
                        DropdownMenuItem(
                          value: index,
                          child: Text(ScheduleUtils.remindWays[index]),
                        ),
                    ],
                    onChanged: (value) async {
                      if (value == null) {
                        return;
                      }
                      await store.updateSettings(
                        settings.copyWith(remindWay: value),
                      );
                      if (context.mounted && value != 1) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('移动端权限需要在系统设置中确认')),
                        );
                      }
                    },
                  ),
                ),
                _SettingRow(
                  label: '闹钟设置',
                  trailing: DropdownButton<int>(
                    value: settings.alarmWay.clamp(
                      0,
                      ScheduleUtils.alarmWays.length - 1,
                    ),
                    items: [
                      for (
                        var index = 0;
                        index < ScheduleUtils.alarmWays.length;
                        index++
                      )
                        DropdownMenuItem(
                          value: index,
                          child: Text(ScheduleUtils.alarmWays[index]),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        store.updateSettings(
                          settings.copyWith(alarmWay: value),
                        );
                      }
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: Row(
                    children: [
                      const Text('课程时间', style: TextStyle(fontSize: 16)),
                      const Spacer(),
                      const Text('当前节数'),
                      const SizedBox(width: 20),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _startTimesController,
                        builder: (context, value, child) {
                          final count = value.text
                              .split('\n')
                              .map((line) => line.trim())
                              .where((line) => line.isNotEmpty)
                              .length;
                          return Text(
                            '$count',
                            style: const TextStyle(color: Color(0xff3174f1)),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _startTimesController,
                  minLines: 8,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _saveStartTimes(),
                  onEditingComplete: _saveStartTimes,
                  onTapOutside: (_) => _saveStartTimes(),
                ),
                _SettingRow(
                  label: '重置设置',
                  trailing: OutlinedButton(
                    onPressed: _confirmReset,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: const BorderSide(
                        color: Color(0xff3174f1),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('确认重置', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickTermStartDate() async {
    final store = ScheduleScope.of(context);
    final current = ScheduleUtils.termStartDate(store.settings);
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(current.year - 2),
      lastDate: DateTime(current.year + 2),
      helpText: '选择第一周第一天',
      cancelText: '取消',
      confirmText: '确定',
    );
    if (picked == null) {
      return;
    }
    await store.updateSettings(
      store.settings.copyWith(
        termStartDate: ScheduleUtils.formatDate(picked),
        termMonth: picked.month,
        termDay: picked.day,
      ),
    );
  }

  Future<void> _saveMaxWeeks() async {
    final store = ScheduleScope.of(context);
    final oldMaxWeeks = store.settings.maxWeeks;
    final maxWeeks = int.tryParse(_maxWeeksController.text);
    if (maxWeeks == null || maxWeeks < 1 || maxWeeks > 53) {
      _toast('请输入正确的最大周数');
      return;
    }
    if (maxWeeks != oldMaxWeeks) {
      final sync = await _showSyncDialog();
      if (sync == null) {
        return;
      }
      await store.syncMaxWeeks(
        oldMaxWeeks: oldMaxWeeks,
        newMaxWeeks: maxWeeks,
        expandWholeTermCourses: sync,
      );
      await store.updateSettings(store.settings.copyWith(maxWeeks: maxWeeks));
    }
  }

  Future<bool?> _showSyncDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('同步课程'),
          content: const Text(
            '是否将新的总周数应用到所有持续整个学期的课程？\n所有持续时长超出新总周数的课程的持续时长将会被截短。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                '取消',
                style: TextStyle(color: Color(0xffff3f15)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('好的'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveDuration() async {
    final duration = int.tryParse(_durationController.text);
    if (duration == null || duration < 1 || duration > 1440) {
      _toast('请输入正确的课程时长');
      return;
    }
    final store = ScheduleScope.of(context);
    await store.updateSettings(
      store.settings.copyWith(durationPerLesson: duration),
    );
  }

  Future<void> _saveReminderTime() async {
    final reminder = int.tryParse(_reminderController.text);
    if (reminder == null || reminder < 0 || reminder > 1440) {
      _toast('请输入正确的提醒时间');
      return;
    }
    final store = ScheduleScope.of(context);
    await store.updateSettings(store.settings.copyWith(reminderTime: reminder));
  }

  Future<void> _saveStartTimes() async {
    final times = _startTimesController.text
        .split('\n')
        .map((line) => line.trim().replaceAll('：', ':'))
        .where((line) => line.isNotEmpty)
        .toList();
    if (!ScheduleUtils.isTimeListValid(times)) {
      _toast('请输入正确的开始时间');
      return;
    }
    final store = ScheduleScope.of(context);
    await store.updateSettings(store.settings.copyWith(startTimes: times));
  }

  Future<void> _confirmReset() async {
    final store = ScheduleScope.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('重置设置'),
          content: const Text('确认重置设置吗（已添加的课程将保留）？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                '确认',
                style: TextStyle(color: Color(0xffff3f15)),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      await store.resetSettings();
      if (mounted) {
        _toast('设置已重置');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AppSettingsPage()),
        );
      }
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.label, required this.trailing});

  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 60),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xffeeeeee))),
      ),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          const Spacer(),
          trailing,
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.width,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final double width;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onSubmitted: onSubmitted,
        onEditingComplete: () => onSubmitted(controller.text),
        onTapOutside: (_) => onSubmitted(controller.text),
      ),
    );
  }
}
