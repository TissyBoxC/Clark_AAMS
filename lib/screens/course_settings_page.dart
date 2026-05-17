import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/course.dart';
import '../models/school.dart';
import '../resources/app_strings.dart';
import '../screens/academic_import_page.dart';
import '../services/clark_backend_api.dart';
import '../services/course_json_importer.dart';
import '../services/lesson_time_defaults.dart';
import '../services/schedule_scope.dart';
import '../services/schedule_utils.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/course_form_dialog.dart';
import '../widgets/top_bar.dart';
import 'home_page.dart';
import 'term_lesson_setup_page.dart';
import 'welcome_page.dart';

class CourseSettingsPage extends StatefulWidget {
  const CourseSettingsPage({super.key});

  @override
  State<CourseSettingsPage> createState() => _CourseSettingsPageState();
}

class _CourseSettingsPageState extends State<CourseSettingsPage> {
  bool _batchDeleteMode = false;
  final Set<int> _selectedIds = <int>{};

  @override
  Widget build(BuildContext context) {
    final store = ScheduleScope.of(context);
    final courses = store.courses;

    return Scaffold(
      backgroundColor: const Color(0xfff6f8fb),
      body: Stack(
        children: [
          Column(
            children: [
              TopBar(
                title: AppStrings.courseSettingsTitle,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _goBack,
                ),
                trailing: _batchDeleteMode
                    ? const SizedBox(width: 48)
                    : PopupMenuButton<_CourseMenu>(
                        icon: const Icon(
                          Icons.more_horiz,
                          color: Color(0xff808080),
                        ),
                        onSelected: (value) {
                          switch (value) {
                            case _CourseMenu.importSchedule:
                              _showImportMethodSheet();
                            case _CourseMenu.batchAdd:
                              _showBatchAddDialog();
                            case _CourseMenu.batchDelete:
                              setState(() {
                                _batchDeleteMode = true;
                                _selectedIds.clear();
                              });
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: _CourseMenu.importSchedule,
                            child: Text(AppStrings.importCourses),
                          ),
                          PopupMenuItem(
                            value: _CourseMenu.batchAdd,
                            child: Text(AppStrings.batchAdd),
                          ),
                          PopupMenuItem(
                            value: _CourseMenu.batchDelete,
                            child: Text(AppStrings.batchDelete),
                          ),
                        ],
                      ),
              ),
              Expanded(
                child: courses.isEmpty
                    ? const Center(
                        child: Text(
                          AppStrings.chooseImportFromTopRight,
                          style: TextStyle(color: Color(0xff808080)),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(
                          10,
                          10,
                          10,
                          _batchDeleteMode ? 70 : 100,
                        ),
                        itemCount: courses.length,
                        itemBuilder: (context, index) {
                          return _CourseListCard(
                            course: courses[index],
                            batchDeleteMode: _batchDeleteMode,
                            selected: _selectedIds.contains(courses[index].id),
                            onSelectChanged: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedIds.add(courses[index].id);
                                } else {
                                  _selectedIds.remove(courses[index].id);
                                }
                              });
                            },
                            onEdit: () => _showCourseDialog(courses[index]),
                            onColor: () =>
                                _showCourseColorDialog(courses[index]),
                            onDelete: () => _confirmDelete(courses[index]),
                          );
                        },
                      ),
              ),
              if (_batchDeleteMode)
                _BatchDeleteBar(
                  allSelected:
                      courses.isNotEmpty &&
                      _selectedIds.length == courses.length,
                  onSelectAll: (selected) {
                    setState(() {
                      _selectedIds
                        ..clear()
                        ..addAll(
                          selected
                              ? courses.map((course) => course.id)
                              : const <int>[],
                        );
                    });
                  },
                  onConfirm: _confirmBatchDelete,
                ),
            ],
          ),
          if (!_batchDeleteMode)
            Positioned(
              right: 16,
              bottom: 32,
              child: FloatingActionButton(
                onPressed: () => _showCourseDialog(),
                child: const Icon(Icons.add),
              ),
            ),
        ],
      ),
    );
  }

  void _goBack() {
    final store = ScheduleScope.of(context);
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    navigator.pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            store.settings.schoolId.isEmpty || store.settings.isFirstLaunch
            ? const WelcomePage()
            : const HomePage(),
      ),
    );
  }

  Future<void> _showCourseDialog([Course? course]) async {
    final store = ScheduleScope.of(context);
    final result = await showDialog<Course>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return CourseFormDialog(
          maxWeeks: store.settings.maxWeeks,
          maxLessons: ScheduleUtils.lessonCount(store.settings, store.courses),
          initialCourse: course,
        );
      },
    );
    if (result == null) {
      return;
    }
    if (course == null) {
      await store.addCourse(
        result.copyWith(
          colorValue: ScheduleUtils.defaultColorForName(result.name).toARGB32(),
        ),
      );
      if (store.settings.isFirstLaunch) {
        await store.markLaunched();
      }
    } else {
      final keepParsedWeeks =
          result.startWeek == course.startWeek &&
          result.endWeek == course.endWeek;
      await store.updateCourse(
        course.id,
        result.copyWith(
          teacher: course.teacher,
          rawTime: course.rawTime,
          activeWeeks: keepParsedWeeks ? course.activeWeeks : const <int>[],
          colorValue: course.colorValue,
        ),
      );
    }
  }

  Future<void> _showCourseColorDialog(Course course) async {
    final store = ScheduleScope.of(context);
    final selected = await showDialog<Color>(
      context: context,
      builder: (context) => _CourseColorDialog(course: course),
    );
    if (selected == null) {
      return;
    }
    await store.updateCourse(
      course.id,
      course.copyWith(colorValue: selected.toARGB32()),
    );
  }

  Future<void> _confirmDelete(Course course) async {
    final store = ScheduleScope.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text(AppStrings.deleteCourseTitle),
          content: Text(AppStrings.deleteCourseMessage(course.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(AppStrings.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                AppStrings.delete,
                style: TextStyle(color: Color(0xffff3f15)),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      await store.deleteCourse(course.id);
      if (mounted) {
        AppSnackBar.show(context, AppStrings.courseDeleted(course.name));
      }
    }
  }

  Future<void> _confirmBatchDelete() async {
    if (_selectedIds.isEmpty) {
      return;
    }
    final store = ScheduleScope.of(context);
    final names = store.courses
        .where((course) => _selectedIds.contains(course.id))
        .map((course) => '· ${course.name}')
        .join('\n');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(AppStrings.deleteCoursesTitle),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 360),
            child: SingleChildScrollView(
              child: Text(AppStrings.deleteCoursesMessage(names)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(AppStrings.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                AppStrings.confirmDelete,
                style: TextStyle(color: Color(0xffff3f15)),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      await store.deleteCourses(_selectedIds);
      if (mounted) {
        setState(() {
          _batchDeleteMode = false;
          _selectedIds.clear();
        });
      }
    }
  }

  Future<void> _showBatchAddDialog() async {
    final store = ScheduleScope.of(context);
    final result = await showDialog<List<Course>>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          _BatchAddDialog(exportJson: store.exportCoursesJson()),
    );
    if (result != null && result.isNotEmpty) {
      final imported = await _importCoursesAndSetTermStart(result);
      if (mounted && imported) {
        AppSnackBar.show(context, AppStrings.coursesAdded(result.length));
      }
    }
  }

  Future<void> _showImportMethodSheet() async {
    final store = ScheduleScope.of(context);
    School? school;
    if (store.settings.hasSpecificSchool) {
      school = await _loadSelectedSchool(store.settings.schoolId);
      if (!mounted) {
        return;
      }
    }
    final method = await showModalBottomSheet<_ImportMethod>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final academicSubtitle = school == null
            ? AppStrings.schoolImportRequiresSupportedSchool
            : '${school.name}(${school.shortName})';
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.document_scanner),
                title: const Text(AppStrings.importByOcr),
                subtitle: const Text(AppStrings.importByOcrSubtitle),
                onTap: () => Navigator.of(context).pop(_ImportMethod.ocr),
              ),
              ListTile(
                leading: const Icon(Icons.key),
                title: const Text(AppStrings.importByPickupCode),
                subtitle: const Text(AppStrings.importByPickupCodeSubtitle),
                onTap: () =>
                    Navigator.of(context).pop(_ImportMethod.pickupCode),
              ),
              ListTile(
                leading: const Icon(Icons.public),
                title: const Text(AppStrings.importByAcademic),
                subtitle: Text(academicSubtitle),
                onTap: () => Navigator.of(context).pop(_ImportMethod.academic),
              ),
            ],
          ),
        );
      },
    );

    switch (method) {
      case _ImportMethod.ocr:
        await _importFromOcr();
      case _ImportMethod.pickupCode:
        await _importFromPickupCode();
      case _ImportMethod.academic:
        await _importFromAcademicSystem(school);
      case null:
        if (store.settings.isFirstLaunch && store.courses.isEmpty) {
          await _resetSchoolSelection();
        }
        return;
    }
  }

  Future<void> _importFromOcr() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 92);
    if (picked.isEmpty) {
      return;
    }

    _showBlockingMessage(AppStrings.recognizingCourseImage);
    try {
      final result = await ClarkBackendApi.instance.recognizeCourseImages(
        picked.map((item) => File(item.path)).toList(),
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();

      await _showPickupCodeResult(result.pickupCode);
      if (!mounted) {
        return;
      }
      if (result.courses.isEmpty) {
        _showUnavailable(AppStrings.noCoursesRecognized);
        return;
      }
      final imported = await _importCoursesAndSetTermStart(result.courses);
      if (mounted && imported) {
        AppSnackBar.show(
          context,
          AppStrings.coursesImported(result.courses.length),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      _showUnavailable(AppStrings.ocrImportFailed(error));
    }
  }

  Future<void> _showPickupCodeResult(String pickupCode) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(AppStrings.recognitionCompleted),
          content: SelectableText(AppStrings.pickupCodeLabel(pickupCode)),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: pickupCode));
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text(AppStrings.copyPickupCode),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(AppStrings.continueImport),
            ),
          ],
        );
      },
    );
  }

  Future<void> _importFromPickupCode() async {
    final code = await showDialog<String>(
      context: context,
      builder: (context) => const _PickupCodeDialog(),
    );
    if (code == null || code.isEmpty) {
      return;
    }

    _showBlockingMessage(AppStrings.fetchingCourses);
    try {
      final courses = await ClarkBackendApi.instance.getCoursesByPickupCode(
        code,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      if (courses.isEmpty) {
        _showUnavailable(AppStrings.pickupCodeNoCourses);
        return;
      }
      final imported = await _importCoursesAndSetTermStart(courses);
      if (mounted && imported) {
        AppSnackBar.show(context, AppStrings.coursesImported(courses.length));
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      _showUnavailable(AppStrings.pickupCodeImportFailed(error));
    }
  }

  void _showBlockingMessage(String message) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                const SizedBox(width: 16),
                Expanded(child: Text(message)),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _canUseAcademicImport(School school) {
    return school.supportsAcademicImport &&
        school.login.mode == 'webview' &&
        school.login.loginUrl.isNotEmpty;
  }

  Future<School?> _loadSelectedSchool(String schoolId) async {
    if (schoolId.isEmpty) {
      _showUnavailable(AppStrings.selectSchoolFirst);
      return null;
    }
    try {
      return await ClarkBackendApi.instance.getSchool(schoolId);
    } catch (error) {
      _showUnavailable(AppStrings.schoolConfigLoadFailed(error));
      return null;
    }
  }

  Future<void> _importFromAcademicSystem(School? school) async {
    if (school == null || !_canUseAcademicImport(school)) {
      _showUnavailable(AppStrings.academicImportNotConfigured);
      return;
    }

    final courses = await Navigator.of(context).push<List<Course>>(
      MaterialPageRoute(builder: (_) => AcademicImportPage(school: school)),
    );
    if (courses == null) {
      await _resetSchoolSelection();
      return;
    }
    if (courses.isEmpty) {
      return;
    }
    final imported = await _importCoursesAndSetTermStart(courses);
    if (!mounted) {
      return;
    }
    if (!imported) {
      return;
    }
    AppSnackBar.show(context, AppStrings.coursesImported(courses.length));
  }

  Future<void> _resetSchoolSelection() async {
    final store = ScheduleScope.of(context);
    await store.resetSchoolSelection();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomePage()),
      (route) => false,
    );
  }

  void _showUnavailable(String message) {
    AppSnackBar.show(context, message);
  }

  Future<bool> _importCoursesAndSetTermStart(List<Course> courses) async {
    final store = ScheduleScope.of(context);
    final setup = await _askTermAndLessonTimesAfterImport(courses);
    if (setup == null) {
      return false;
    }
    if (!mounted) {
      return false;
    }
    final coloredCourses = _withDefaultColors(courses);
    final customizedCourses = await _showImportedCourseColorsDialog(
      coloredCourses,
    );
    if (customizedCourses == null) {
      return false;
    }
    await store.importCourses(customizedCourses);
    await store.updateSettings(
      store.settings.copyWith(
        isFirstLaunch: false,
        termStartDate: ScheduleUtils.formatDate(setup.termStartDate),
        termMonth: setup.termStartDate.month,
        termDay: setup.termStartDate.day,
        startTimes: setup.startTimes,
      ),
    );
    return true;
  }

  List<Course> _withDefaultColors(List<Course> courses) {
    return [
      for (final course in courses)
        course.colorValue == null
            ? course.copyWith(
                colorValue: ScheduleUtils.defaultColorForName(
                  course.name,
                ).toARGB32(),
              )
            : course,
    ];
  }

  Future<List<Course>?> _showImportedCourseColorsDialog(List<Course> courses) {
    return showDialog<List<Course>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ImportedCourseColorsDialog(courses: courses),
    );
  }

  Future<TermLessonSetupResult?> _askTermAndLessonTimesAfterImport(
    List<Course> courses,
  ) async {
    final store = ScheduleScope.of(context);
    final initialDate = store.settings.termStartDate.isEmpty
        ? DateTime.now()
        : ScheduleUtils.termStartDate(store.settings);
    final lessonCount = ScheduleUtils.lessonCount(store.settings, courses);
    final defaults = await LessonTimeDefaults.resolve(store, courses: courses);
    if (!mounted) {
      return null;
    }
    return Navigator.of(context).push<TermLessonSetupResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => TermLessonSetupPage(
          initialTermStartDate: initialDate,
          initialStartTimes: defaults.initialStartTimes,
          lessonCount: lessonCount,
          title: AppStrings.selectFirstWeekFirstDayTitle,
          subtitle: AppStrings.importTermSetupSubtitle,
          confirmText: AppStrings.continueImportAction,
          cancelText: AppStrings.cancelImport,
          lessonTimeProfiles: defaults.generalProfiles,
          lessonTimeNotice: defaults.notice,
        ),
      ),
    );
  }
}

enum _CourseMenu { importSchedule, batchAdd, batchDelete }

enum _ImportMethod { ocr, pickupCode, academic }

class _CourseListCard extends StatelessWidget {
  const _CourseListCard({
    required this.course,
    required this.batchDeleteMode,
    required this.selected,
    required this.onSelectChanged,
    required this.onEdit,
    required this.onColor,
    required this.onDelete,
  });

  final Course course;
  final bool batchDeleteMode;
  final bool selected;
  final ValueChanged<bool> onSelectChanged;
  final VoidCallback onEdit;
  final VoidCallback onColor;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final store = ScheduleScope.of(context);
    final timeRange = ScheduleUtils.timeRange(store.settings, course);

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 16),
      child: Row(
        children: [
          if (batchDeleteMode)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: IconButton(
                onPressed: () => onSelectChanged(!selected),
                icon: Icon(
                  selected ? Icons.delete : Icons.delete_outline,
                  color: selected
                      ? const Color(0xffff3f15)
                      : const Color(0xffb0b0b0),
                ),
              ),
            ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xfffff1ed)
                    : Theme.of(context).colorScheme.surface,
                border: Border.all(color: const Color(0xffe2e8f0)),
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0f172033),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 5,
                        height: 38,
                        margin: const EdgeInsets.only(right: 12, top: 2),
                        decoration: BoxDecoration(
                          color: ScheduleUtils.colorForCourse(course),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          course.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!batchDeleteMode)
                        PopupMenuButton<_CourseItemMenu>(
                          icon: const Icon(
                            Icons.more_horiz,
                            color: Color(0xff808080),
                          ),
                          onSelected: (value) {
                            switch (value) {
                              case _CourseItemMenu.edit:
                                onEdit();
                              case _CourseItemMenu.color:
                                onColor();
                              case _CourseItemMenu.delete:
                                onDelete();
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: _CourseItemMenu.edit,
                              child: Text(AppStrings.edit),
                            ),
                            PopupMenuItem(
                              value: _CourseItemMenu.color,
                              child: Text(AppStrings.color),
                            ),
                            PopupMenuItem(
                              value: _CourseItemMenu.delete,
                              child: Text(AppStrings.delete),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _InfoLine(
                    label: AppStrings.weekRangeLabel,
                    value: course.weekText,
                  ),
                  _InfoLine(
                    label: AppStrings.classTimeLabel,
                    value: timeRange.isEmpty
                        ? ScheduleUtils.dayLabels[course.dayOfWeek - 1]
                        : '${ScheduleUtils.dayLabels[course.dayOfWeek - 1]}  $timeRange',
                  ),
                  _InfoLine(
                    label: AppStrings.courseLocationLabel,
                    value: course.location,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _CourseItemMenu { edit, color, delete }

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Color(0xff808080))),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              value.isEmpty ? AppStrings.notSet : value,
              style: const TextStyle(color: Color(0xff808080)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _BatchDeleteBar extends StatelessWidget {
  const _BatchDeleteBar({
    required this.allSelected,
    required this.onSelectAll,
    required this.onConfirm,
  });

  final bool allSelected;
  final ValueChanged<bool> onSelectAll;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 12,
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 50,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Checkbox(
                  value: allSelected,
                  onChanged: (value) => onSelectAll(value ?? false),
                ),
                const Text(
                  AppStrings.selectAll,
                  style: TextStyle(fontSize: 16),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onConfirm,
                  child: const Text(
                    AppStrings.confirmDelete,
                    style: TextStyle(
                      color: Color(0xffff3f15),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BatchAddDialog extends StatefulWidget {
  const _BatchAddDialog({required this.exportJson});

  final String exportJson;

  @override
  State<_BatchAddDialog> createState() => _BatchAddDialogState();
}

class _BatchAddDialogState extends State<_BatchAddDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.batchAddCoursesTitle),
      content: SizedBox(
        width: 520,
        child: TextField(
          controller: _controller,
          minLines: 10,
          maxLines: 10,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: AppStrings.courseJsonHint,
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _showHelp, child: const Text(AppStrings.help)),
        TextButton(
          onPressed: _exportJson,
          child: const Text(AppStrings.exportJson),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(onPressed: _save, child: const Text(AppStrings.save)),
      ],
    );
  }

  Future<void> _exportJson() async {
    await Clipboard.setData(ClipboardData(text: widget.exportJson));
    if (mounted) {
      AppSnackBar.show(context, AppStrings.copiedToClipboard);
    }
  }

  void _showHelp() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return const AlertDialog(
          title: Text(AppStrings.batchAddHelpTitle),
          content: SingleChildScrollView(
            child: Text(AppStrings.batchAddHelpExample),
          ),
        );
      },
    );
  }

  void _save() {
    try {
      final courses = CourseJsonImporter.parse(_controller.text);
      Navigator.of(context).pop(courses);
    } on FormatException catch (error) {
      _toast(error.message);
    } catch (_) {
      _toast(AppStrings.invalidJsonInput);
    }
  }

  void _toast(String message) {
    AppSnackBar.show(context, message);
  }
}

class _CourseColorDialog extends StatelessWidget {
  const _CourseColorDialog({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    final current = ScheduleUtils.colorForCourse(course);
    return AlertDialog(
      title: Text(AppStrings.selectColorForCourse(course.name)),
      content: _ColorGrid(
        selected: current,
        onSelected: (color) => Navigator.of(context).pop(color),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
      ],
    );
  }
}

class _ImportedCourseColorsDialog extends StatefulWidget {
  const _ImportedCourseColorsDialog({required this.courses});

  final List<Course> courses;

  @override
  State<_ImportedCourseColorsDialog> createState() =>
      _ImportedCourseColorsDialogState();
}

class _ImportedCourseColorsDialogState
    extends State<_ImportedCourseColorsDialog> {
  late List<Course> _courses;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _courses = [...widget.courses];
  }

  @override
  Widget build(BuildContext context) {
    final selectedCourse = _courses[_selectedIndex];
    return AlertDialog(
      title: const Text(AppStrings.setCourseColor),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _courses.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final course = _courses[index];
                  final selected = index == _selectedIndex;
                  return Material(
                    color: selected
                        ? const Color(0xffe6f3f1)
                        : const Color(0xfff8fafc),
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => setState(() => _selectedIndex = index),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 9,
                        ),
                        child: Row(
                          children: [
                            _ColorDot(
                              color: ScheduleUtils.colorForCourse(course),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                course.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              ScheduleUtils.dayLabels[course.dayOfWeek - 1],
                              style: const TextStyle(color: Color(0xff64748b)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                AppStrings.selectedCourseLabel(selectedCourse.name),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 10),
            _ColorGrid(
              selected: ScheduleUtils.colorForCourse(selectedCourse),
              onSelected: (color) {
                setState(() {
                  _courses[_selectedIndex] = selectedCourse.copyWith(
                    colorValue: color.toARGB32(),
                  );
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_courses),
          child: const Text(AppStrings.confirmImport),
        ),
      ],
    );
  }
}

class _ColorGrid extends StatelessWidget {
  const _ColorGrid({required this.selected, required this.onSelected});

  final Color selected;
  final ValueChanged<Color> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final color in ScheduleUtils.courseColors)
          Tooltip(
            message: '#${color.toARGB32().toRadixString(16).padLeft(8, '0')}',
            child: InkWell(
              onTap: () => onSelected(color),
              borderRadius: BorderRadius.circular(99),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.toARGB32() == selected.toARGB32()
                        ? Colors.black
                        : Colors.white,
                    width: color.toARGB32() == selected.toARGB32() ? 3 : 2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _PickupCodeDialog extends StatefulWidget {
  const _PickupCodeDialog();

  @override
  State<_PickupCodeDialog> createState() => _PickupCodeDialogState();
}

class _PickupCodeDialogState extends State<_PickupCodeDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.enterPickupCodeTitle),
      content: TextField(
        controller: _controller,
        maxLength: 8,
        textCapitalization: TextCapitalization.characters,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: AppStrings.pickupCodeHint,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: () {
            final code = _controller.text.trim().toUpperCase();
            if (code.length != 8) {
              AppSnackBar.show(context, AppStrings.enterEightDigitPickupCode);
              return;
            }
            Navigator.of(context).pop(code);
          },
          child: const Text(AppStrings.import),
        ),
      ],
    );
  }
}
