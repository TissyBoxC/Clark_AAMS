import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/course.dart';
import '../models/school.dart';
import '../screens/academic_import_page.dart';
import '../services/clark_backend_api.dart';
import '../services/course_json_importer.dart';
import '../services/schedule_scope.dart';
import '../services/schedule_utils.dart';
import '../widgets/course_form_dialog.dart';
import '../widgets/top_bar.dart';
import 'home_page.dart';
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
                title: '课程设置',
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
                            child: Text('导入课程'),
                          ),
                          PopupMenuItem(
                            value: _CourseMenu.batchAdd,
                            child: Text('批量添加'),
                          ),
                          PopupMenuItem(
                            value: _CourseMenu.batchDelete,
                            child: Text('批量删除'),
                          ),
                        ],
                      ),
              ),
              Expanded(
                child: courses.isEmpty
                    ? const Center(
                        child: Text(
                          '点击右上角选择导入课程',
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
          maxLessons: store.settings.startTimes.length,
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
          title: const Text('删除课程'),
          content: Text('确定要删除“${course.name}”吗？此操作不可撤销。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                '删除',
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('已成功删除课程：${course.name}')));
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
          title: const Text('删除多门课程'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 360),
            child: SingleChildScrollView(child: Text('确定删除以下课程吗？\n\n$names')),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                '确定删除',
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('成功添加 ${result.length} 门课程')));
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
            ? '需先选择支持教务系统导入的学校'
            : '${school.name}(${school.shortName})';
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.document_scanner),
                title: const Text('使用OCR导入'),
                subtitle: const Text('识别课表图片后导入课程'),
                onTap: () => Navigator.of(context).pop(_ImportMethod.ocr),
              ),
              ListTile(
                leading: const Icon(Icons.key),
                title: const Text('使用取件码导入'),
                subtitle: const Text('输入取件码获取课程数据'),
                onTap: () =>
                    Navigator.of(context).pop(_ImportMethod.pickupCode),
              ),
              ListTile(
                leading: const Icon(Icons.public),
                title: const Text('教务系统导入'),
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
        _showUnavailable('OCR导入暂未配置');
      case _ImportMethod.pickupCode:
        _showUnavailable('取件码导入暂未配置');
      case _ImportMethod.academic:
        await _importFromAcademicSystem(school);
      case null:
        if (store.settings.isFirstLaunch && store.courses.isEmpty) {
          await _resetSchoolSelection();
        }
        return;
    }
  }

  bool _canUseAcademicImport(School school) {
    return school.supportsAcademicImport &&
        school.login.mode == 'webview' &&
        school.login.loginUrl.isNotEmpty;
  }

  Future<School?> _loadSelectedSchool(String schoolId) async {
    if (schoolId.isEmpty) {
      _showUnavailable('请先选择学校');
      return null;
    }
    try {
      return await ClarkBackendApi.instance.getSchool(schoolId);
    } catch (error) {
      _showUnavailable('学校配置加载失败：$error');
      return null;
    }
  }

  Future<void> _importFromAcademicSystem(School? school) async {
    if (school == null || !_canUseAcademicImport(school)) {
      _showUnavailable('当前学校未配置教务系统导入方法');
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('成功导入 ${courses.length} 门课程')));
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _importCoursesAndSetTermStart(List<Course> courses) async {
    final store = ScheduleScope.of(context);
    final termStartDate = await _askTermStartDateAfterImport();
    if (termStartDate == null) {
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
        termStartDate: ScheduleUtils.formatDate(termStartDate),
        termMonth: termStartDate.month,
        termDay: termStartDate.day,
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

  Future<DateTime?> _askTermStartDateAfterImport() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: DateTime(today.year - 2),
      lastDate: DateTime(today.year + 2),
      helpText: '选择该学期第一周第一天',
      cancelText: '取消导入',
      confirmText: '确定',
    );
    return picked;
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
                              child: Text('编辑'),
                            ),
                            PopupMenuItem(
                              value: _CourseItemMenu.color,
                              child: Text('颜色'),
                            ),
                            PopupMenuItem(
                              value: _CourseItemMenu.delete,
                              child: Text('删除'),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _InfoLine(label: '起止周', value: course.weekText),
                  _InfoLine(
                    label: '上课时间',
                    value:
                        '${ScheduleUtils.dayLabels[course.dayOfWeek - 1]}  ${ScheduleUtils.timeRange(store.settings, course)}',
                  ),
                  _InfoLine(label: '课程地点', value: course.location),
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
              value.isEmpty ? '未设置' : value,
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
                const Text('全选', style: TextStyle(fontSize: 16)),
                const Spacer(),
                TextButton(
                  onPressed: onConfirm,
                  child: const Text(
                    '确认删除',
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
      title: const Text('批量添加课程'),
      content: SizedBox(
        width: 520,
        child: TextField(
          controller: _controller,
          minLines: 10,
          maxLines: 10,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: '粘贴课程 JSON 数组',
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _showHelp, child: const Text('使用说明')),
        TextButton(onPressed: _exportJson, child: const Text('导出JSON')),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _save, child: const Text('保存')),
      ],
    );
  }

  Future<void> _exportJson() async {
    await Clipboard.setData(ClipboardData(text: widget.exportJson));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已复制到剪贴板')));
    }
  }

  void _showHelp() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return const AlertDialog(
          title: Text('批量添加说明'),
          content: SingleChildScrollView(
            child: Text(
              '[\n'
              '  {\n'
              '    "name": "高等数学",\n'
              '    "startWeek": 1,\n'
              '    "endWeek": 18,\n'
              '    "dayOfWeek": 1,\n'
              '    "startLesson": 1,\n'
              '    "endLesson": 2,\n'
              '    "location": "A101"\n'
              '  }\n'
              ']',
            ),
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
      _toast('输入的JSON格式错误');
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _CourseColorDialog extends StatelessWidget {
  const _CourseColorDialog({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    final current = ScheduleUtils.colorForCourse(course);
    return AlertDialog(
      title: Text('选择颜色：${course.name}'),
      content: _ColorGrid(
        selected: current,
        onSelected: (color) => Navigator.of(context).pop(color),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
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
      title: const Text('设置课程颜色'),
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
                '当前：${selectedCourse.name}',
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
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_courses),
          child: const Text('确认导入'),
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
