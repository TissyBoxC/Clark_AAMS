import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/app_settings.dart';
import '../models/school.dart';
import '../services/clark_backend_api.dart';
import '../services/lesson_time_defaults.dart';
import '../services/schedule_scope.dart';
import '../services/schedule_utils.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/top_bar.dart';
import 'term_lesson_setup_page.dart';
import 'welcome_page.dart';

class AppSettingsPage extends StatefulWidget {
  const AppSettingsPage({super.key});

  @override
  State<AppSettingsPage> createState() => _AppSettingsPageState();
}

class _AppSettingsPageState extends State<AppSettingsPage> {
  late TextEditingController _maxWeeksController;
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
    _controllersReady = true;
  }

  @override
  void dispose() {
    if (_controllersReady) {
      _maxWeeksController.dispose();
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
                _SchoolSettingRow(
                  schoolId: settings.schoolId,
                  onReselect: _confirmResetSchoolSelection,
                ),
                _SettingRow(
                  label: '第一周第一天',
                  trailing: TextButton(
                    onPressed: _configureTermAndTimes,
                    child: Text(
                      settings.termStartDate.isEmpty
                          ? '未设置'
                          : ScheduleUtils.localDateLabel(
                              ScheduleUtils.termStartDate(settings),
                            ),
                    ),
                  ),
                ),
                _SettingRow(
                  label: '每节课时间',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        settings.startTimes
                                .where((time) => time.isNotEmpty)
                                .isEmpty
                            ? '未配置'
                            : '已配置',
                        style: TextStyle(
                          color:
                              settings.startTimes
                                  .where((time) => time.isNotEmpty)
                                  .isEmpty
                              ? const Color(0xff9a92aa)
                              : const Color(0xff6d64ff),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        onPressed: _configureTermAndTimes,
                        icon: const Icon(Icons.schedule_rounded, size: 18),
                        label: const Text('配置'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          minimumSize: const Size(78, 38),
                        ),
                      ),
                    ],
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

  Future<void> _configureTermAndTimes() async {
    final store = ScheduleScope.of(context);
    final current = store.settings.termStartDate.isEmpty
        ? DateTime.now()
        : ScheduleUtils.termStartDate(store.settings);
    final defaults = await LessonTimeDefaults.resolve(
      store,
      courses: store.courses,
    );
    if (!mounted) {
      return;
    }
    final result = await Navigator.of(context).push<TermLessonSetupResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => TermLessonSetupPage(
          initialTermStartDate: current,
          initialStartTimes: defaults.initialStartTimes,
          lessonCount: ScheduleUtils.lessonCount(store.settings, store.courses),
          title: '学期与节次时间',
          subtitle: '第一周第一天用于计算当前周数；每节课开始时间用于桌面小组件匹配下一节课。',
          lessonTimeProfiles: defaults.generalProfiles,
          lessonTimeNotice: defaults.notice,
        ),
      ),
    );
    if (result == null) {
      return;
    }
    await store.updateSettings(
      store.settings.copyWith(
        termStartDate: ScheduleUtils.formatDate(result.termStartDate),
        termMonth: result.termStartDate.month,
        termDay: result.termStartDate.day,
        startTimes: result.startTimes,
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

  Future<void> _confirmResetSchoolSelection() async {
    final store = ScheduleScope.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('重置学校选择'),
          content: const Text('确认重新选择学校吗？本地已保存的课程将被删除。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('确认'),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      await store.resetSchoolSelection();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WelcomePage()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _confirmReset() async {
    final store = ScheduleScope.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('重置设置'),
          content: const Text('确认重置设置吗？本地已保存的课程将被删除。'),
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
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WelcomePage()),
          (route) => false,
        );
      }
    }
  }

  void _toast(String message) {
    AppSnackBar.show(context, message);
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

class _SchoolSettingRow extends StatelessWidget {
  const _SchoolSettingRow({required this.schoolId, required this.onReselect});

  final String schoolId;
  final VoidCallback onReselect;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 68),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xffeeeeee))),
      ),
      child: Row(
        children: [
          const Text('学校信息', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 16),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: _SchoolInfoText(schoolId: schoolId),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: onReselect,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              side: const BorderSide(color: Color(0xff3174f1), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('重选学校', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _SchoolInfoText extends StatelessWidget {
  const _SchoolInfoText({required this.schoolId});

  final String schoolId;

  @override
  Widget build(BuildContext context) {
    if (schoolId.isEmpty) {
      return const Text(
        '未选择学校',
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Color(0xff808080)),
      );
    }
    if (schoolId == AppSettingsModel.unspecifiedSchoolId) {
      return const Text(
        '其他方式导入',
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Color(0xff808080)),
      );
    }
    return FutureBuilder<School>(
      future: ClarkBackendApi.instance.getSchool(schoolId),
      builder: (context, snapshot) {
        final school = snapshot.data;
        final text = school == null
            ? schoolId
            : '${school.name}(${school.shortName})';
        return Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.right,
          style: const TextStyle(color: Color(0xff808080)),
        );
      },
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
