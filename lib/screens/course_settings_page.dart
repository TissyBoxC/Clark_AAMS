import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/course.dart';
import '../models/school.dart';
import '../resources/app_strings.dart';
import '../screens/academic_import_page.dart';
import 'course_settings/course_list_widgets.dart';
import 'course_settings/course_settings_dialogs.dart';
import 'course_settings/course_settings_helpers.dart';
import 'course_settings/course_settings_top_bar.dart';
import '../services/clark_backend_api.dart';
import '../services/lesson_time_defaults.dart';
import '../services/schedule_scope.dart';
import '../services/schedule_utils.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/course_form_dialog.dart';
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
              CourseSettingsTopBar(
                batchDeleteMode: _batchDeleteMode,
                onBack: _goBack,
                onImport: _showImportMethodSheet,
                onBatchAdd: _showBatchAddDialog,
                onBatchDelete: () => setState(() {
                  _batchDeleteMode = true;
                  _selectedIds.clear();
                }),
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
                          return CourseListCard(
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
                BatchDeleteBar(
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
          // 周次未变时沿用原周次规则，避免把「1-3,5-16」压平成「1-16」
          weekPattern: keepParsedWeeks
              ? course.weekPattern
              : WeekPattern.empty,
          colorValue: course.colorValue,
        ),
      );
    }
  }

  Future<void> _showCourseColorDialog(Course course) async {
    final store = ScheduleScope.of(context);
    final selected = await showDialog<Color>(
      context: context,
      builder: (context) => CourseColorDialog(course: course),
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
          BatchAddDialog(exportJson: store.exportCoursesJson()),
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
      builder: (context) => const PickupCodeDialog(),
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

  bool _canUseAcademicImport(School school) => canUseAcademicImport(school);

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
    AppSnackBar.show(context, unavailableMessage(message));
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
    // 默认 merge：重复导入同一份课表不会让课程翻倍
    final outcome = await store.importCourses(customizedCourses);
    await store.updateSettings(
      store.settings.copyWith(
        isFirstLaunch: false,
        termStartDate: ScheduleUtils.formatDate(setup.termStartDate),
        termMonth: setup.termStartDate.month,
        termDay: setup.termStartDate.day,
        startTimes: setup.startTimes,
      ),
    );
    if (!mounted) {
      return true;
    }
    if (outcome.added == 0 && outcome.updated == 0) {
      AppSnackBar.show(
        context,
        AppStrings.importUnchanged(outcome.skipped),
      );
    } else {
      AppSnackBar.show(
        context,
        AppStrings.importSummary(
          added: outcome.added,
          updated: outcome.updated,
          skipped: outcome.skipped,
        ),
      );
    }
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
      builder: (context) => ImportedCourseColorsDialog(courses: courses),
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


enum _ImportMethod { ocr, pickupCode, academic }
