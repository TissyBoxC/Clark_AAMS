import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/app_settings.dart';
import '../models/school.dart';
import '../resources/app_strings.dart';
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
            title: AppStrings.appSettingsTitle,
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
                  label: AppStrings.termFirstDayLabel,
                  trailing: TextButton(
                    onPressed: _configureTermAndTimes,
                    child: Text(
                      settings.termStartDate.isEmpty
                          ? AppStrings.notSet
                          : ScheduleUtils.localDateLabel(
                              ScheduleUtils.termStartDate(settings),
                            ),
                    ),
                  ),
                ),
                _SettingRow(
                  label: AppStrings.lessonTimesLabel,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        settings.startTimes
                                .where((time) => time.isNotEmpty)
                                .isEmpty
                            ? AppStrings.notConfigured
                            : AppStrings.configured,
                        style: TextStyle(
                          color:
                              settings.startTimes
                                  .where((time) => time.isNotEmpty)
                                  .isEmpty
                              ? const Color(0xff9a92aa)
                              : const Color(0xffc93c7d),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        onPressed: _configureTermAndTimes,
                        icon: const Icon(Icons.schedule_rounded, size: 18),
                        label: const Text(AppStrings.configure),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          minimumSize: const Size(78, 38),
                        ),
                      ),
                    ],
                  ),
                ),
                _SettingRow(
                  label: AppStrings.maxWeeksLabel,
                  trailing: _NumberField(
                    controller: _maxWeeksController,
                    width: 140,
                    onSubmitted: (_) => _saveMaxWeeks(),
                  ),
                ),
                _SettingRow(
                  label: AppStrings.resetSettingsLabel,
                  trailing: OutlinedButton(
                    onPressed: _confirmReset,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: const BorderSide(
                        color: Color(0xffc93c7d),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      AppStrings.confirmReset,
                      style: TextStyle(fontSize: 12),
                    ),
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
          title: AppStrings.termAndLessonTimesTitle,
          subtitle: AppStrings.termAndLessonTimesSubtitle,
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
      _toast(AppStrings.invalidMaxWeeks);
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
          title: const Text(AppStrings.syncCoursesTitle),
          content: const Text(AppStrings.syncCoursesMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                AppStrings.cancel,
                style: TextStyle(color: Color(0xffb3304a)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(AppStrings.ok),
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
          title: const Text(AppStrings.resetSchoolSelectionTitle),
          content: const Text(AppStrings.resetSchoolSelectionMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(AppStrings.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(AppStrings.confirm),
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
          title: const Text(AppStrings.resetSettingsLabel),
          content: const Text(AppStrings.resetSettingsMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(AppStrings.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                AppStrings.confirm,
                style: TextStyle(color: Color(0xffb3304a)),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      await store.resetSettings();
      if (mounted) {
        _toast(AppStrings.settingsReset);
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
        border: Border(bottom: BorderSide(color: Color(0xfff7d9e2))),
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
        border: Border(bottom: BorderSide(color: Color(0xfff7d9e2))),
      ),
      child: Row(
        children: [
          const Text(AppStrings.schoolInfo, style: TextStyle(fontSize: 16)),
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
              side: const BorderSide(color: Color(0xffc93c7d), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              AppStrings.reselectSchool,
              style: TextStyle(fontSize: 12),
            ),
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
        AppStrings.noSchoolSelected,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Color(0xff6b4f5a)),
      );
    }
    if (schoolId == AppSettingsModel.unspecifiedSchoolId) {
      return const Text(
        AppStrings.otherImportMethods,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Color(0xff6b4f5a)),
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
          style: const TextStyle(color: Color(0xff6b4f5a)),
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
