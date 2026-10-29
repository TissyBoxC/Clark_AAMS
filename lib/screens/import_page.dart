import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/course.dart';
import '../models/school.dart';
import '../resources/app_colors.dart';
import '../resources/app_metrics.dart';
import '../resources/app_strings.dart';
import '../services/clark_backend_api.dart';
import '../services/schedule_scope.dart';
import '../widgets/app_icons.dart';
import '../widgets/feedback.dart';
import '../widgets/soft_ui.dart';
import '../services/academic_browser.dart';
import 'academic_browser_page.dart';
import 'import_preview.dart';

/// 导入课表页：教务导入 / 截图识别 / 取件码 三种方式。
class ImportPage extends StatefulWidget {
  const ImportPage({super.key});

  @override
  State<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends State<ImportPage> {
  String _mode = 'academic';

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: AppStrings.importTitle,
      description: AppStrings.importSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedTabs(
            value: _mode,
            items: const [
              ('academic', AppStrings.importByAcademic),
              ('ocr', AppStrings.importByOcr),
              ('pickup', AppStrings.importByPickupCode),
            ],
            onChanged: (value) => setState(() => _mode = value),
          ),
          const SizedBox(height: AppMetrics.sp4),
          switch (_mode) {
            'ocr' => const OcrImportSection(),
            'pickup' => const PickupImportSection(),
            _ => const AcademicImportSection(),
          },
        ],
      ),
    );
  }
}

/// 分页切换胶囊。
class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({
    required this.value,
    required this.items,
    required this.onChanged,
    super.key,
  });

  final String value;
  final List<(String, String)> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceSunken,
        borderRadius: BorderRadius.circular(AppMetrics.rPill),
      ),
      child: Row(
        children: [
          for (final (key, label) in items)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(key),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: AppMetrics.fast,
                  curve: AppMetrics.ease,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: value == key
                        ? AppColors.surface
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppMetrics.rPill),
                    boxShadow: value == key ? AppColors.shadowSm : null,
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppMetrics.small,
                      fontWeight: value == key
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: value == key
                          ? AppColors.brand700
                          : AppColors.ink600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// 教务导入
// ============================================================
class AcademicImportSection extends StatefulWidget {
  const AcademicImportSection({super.key});

  @override
  State<AcademicImportSection> createState() => _AcademicImportSectionState();
}

class _AcademicImportSectionState extends State<AcademicImportSection> {
  List<School>? _schools;
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final schools = await ClarkBackendApi.instance.getSchools();
      if (!mounted) {
        return;
      }
      setState(() {
        _schools = schools;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _schools = const [];
        _loading = false;
      });
    }
  }

  /// 打开内置浏览器，登录后读取课表。
  Future<void> _open(School school) async {
    if (!AcademicBrowser.isSupported) {
      AppNotice.show(
        context,
        '这台电脑上暂时打不开学校页面，请改用截图识别导入课表。',
        tone: NoticeTone.warn,
      );
      return;
    }
    if (!AcademicBrowser.hasLoginPage(school)) {
      AppNotice.show(
        context,
        '这所学校还没有配置登录入口，请改用截图识别导入课表。',
        tone: NoticeTone.warn,
      );
      return;
    }

    final store = ScheduleScope.of(context);
    final read = await Navigator.of(context).push<List<Course>>(
      MaterialPageRoute<List<Course>>(
        builder: (_) => AcademicBrowserPage(
          school: school,
          maxWeek: store.settings.maxWeeks,
        ),
      ),
    );
    if (read == null || read.isEmpty || !mounted) {
      return;
    }
    await _applyImport(read);
  }

  Future<void> _applyImport(List<Course> courses) async {
    final store = ScheduleScope.of(context);
    final outcome = await store.importCourses(courses);
    if (!mounted) {
      return;
    }
    AppNotice.success(
      context,
      outcome.changed
          ? '${AppStrings.coursesImported}，新增 ${outcome.added} 门'
          : AppStrings.importUnchanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final schools = _schools ?? const <School>[];
    final keyword = _query.trim();
    final filtered = keyword.isEmpty
        ? schools
        : schools.where((school) => school.name.contains(keyword)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CardHeading(
                title: AppStrings.chooseSchoolTitle,
                subtitle: AppStrings.chooseSchoolSubtitle,
              ),
              const SizedBox(height: AppMetrics.sp4),
              TextField(
                decoration: const InputDecoration(
                  hintText: AppStrings.searchSchoolHint,
                  prefixIcon: Icon(AppIcons.search, size: 20),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppMetrics.sp4),
        if (_loading)
          const SoftCard(child: LoadingPanel())
        else if (filtered.isEmpty)
          SoftCard(
            child: EmptyPanel(
              title: schools.isEmpty
                  ? AppStrings.noSchoolsFromBackend
                  : AppStrings.noMatchedSchool,
              body: schools.isEmpty
                  ? AppStrings.noSchoolsFromBackend
                  : '换个关键词再找一次，或者直接清空搜索框查看全部学校。',
            ),
          )
        else
          SoftCard(
            padding: const EdgeInsets.all(AppMetrics.sp3),
            child: Column(
              children: [
                for (final school in filtered)
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppMetrics.rMd),
                    ),
                    leading: const Icon(AppIcons.school),
                    title: Text(
                      school.name,
                      style: const TextStyle(
                        fontSize: AppMetrics.body,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      school.supportsAcademicImport
                          ? '登录后可以读取整学期课表'
                          : AppStrings.academicImportNotYetConfigured,
                      style: const TextStyle(
                        fontSize: AppMetrics.tiny,
                        color: AppColors.ink500,
                      ),
                    ),
                    trailing: const Icon(AppIcons.chevronRight, size: 20),
                    onTap: () => _open(school),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

// ============================================================
// 截图识别
// ============================================================
class OcrImportSection extends StatefulWidget {
  const OcrImportSection({super.key});

  @override
  State<OcrImportSection> createState() => _OcrImportSectionState();
}

class _OcrImportSectionState extends State<OcrImportSection> {
  final _picker = ImagePicker();
  final List<File> _images = [];
  bool _running = false;
  String _status = AppStrings.noImageChosen;
  String _pickupCode = '';
  List<Course> _courses = const [];

  Future<void> _pick() async {
    final picked = await _picker.pickMultiImage();
    if (picked.isEmpty || !mounted) {
      return;
    }
    setState(() {
      _images
        ..clear()
        ..addAll(picked.take(9).map((file) => File(file.path)));
      _pickupCode = '';
      _courses = const [];
      _status =
          '已选好 ${_images.length} 张图片，点「${AppStrings.startRecognition}」开始读。';
    });
  }

  Future<void> _recognize() async {
    if (_images.isEmpty) {
      setState(() => _status = AppStrings.selectCourseImageFirst);
      return;
    }
    setState(() {
      _running = true;
      _status = AppStrings.recognizingCourseImage;
    });
    try {
      final result = await ClarkBackendApi.instance.recognizeCourseImages(
        _images,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _pickupCode = result.pickupCode;
        _courses = result.courses;
        _status = result.courses.isEmpty
            ? AppStrings.noCoursesRecognized
            : AppStrings.recognitionCompleted;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _status = error is ApiException
            ? error.message
            : AppStrings.ocrImportFailed;
      });
    } finally {
      if (mounted) {
        setState(() => _running = false);
      }
    }
  }

  Future<void> _save() async {
    if (_courses.isEmpty) {
      return;
    }
    final store = ScheduleScope.of(context);
    final outcome = await store.importCourses(_courses);
    if (!mounted) {
      return;
    }
    AppNotice.success(
      context,
      outcome.changed ? AppStrings.coursesImported : AppStrings.importUnchanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.uploadImagesTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink900,
                ),
              ),
              const SizedBox(height: AppMetrics.sp2),
              const HintText(AppStrings.uploadImagesHint),
              const SizedBox(height: AppMetrics.sp4),
              Wrap(
                spacing: AppMetrics.sp2,
                runSpacing: AppMetrics.sp2,
                children: [
                  QuietButton(
                    label: AppStrings.chooseImages,
                    icon: AppIcons.camera,
                    onPressed: _running ? null : _pick,
                  ),
                  if (_images.isNotEmpty)
                    QuietButton(
                      label: AppStrings.clearSelected,
                      onPressed: _running
                          ? null
                          : () => setState(() {
                              _images.clear();
                              _courses = const [];
                              _pickupCode = '';
                              _status = AppStrings.noImageChosen;
                            }),
                    ),
                ],
              ),
              if (_images.isNotEmpty) ...[
                const SizedBox(height: AppMetrics.sp3),
                for (final image in _images)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        const Icon(
                          AppIcons.camera,
                          size: 16,
                          color: AppColors.ink400,
                        ),
                        const SizedBox(width: AppMetrics.sp2),
                        Expanded(
                          child: Text(
                            image.path.split(Platform.pathSeparator).last,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: AppMetrics.tiny,
                              color: AppColors.ink600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: AppMetrics.sp4),
              PrimaryButton(
                label: _running
                    ? AppStrings.recognizingCourseImage
                    : AppStrings.startRecognition,
                loading: _running,
                onPressed: _recognize,
              ),
              const SizedBox(height: AppMetrics.sp3),
              Text(
                _status,
                style: const TextStyle(
                  fontSize: AppMetrics.tiny,
                  color: AppColors.ink500,
                ),
              ),
            ],
          ),
        ),
        if (_pickupCode.isNotEmpty) ...[
          const SizedBox(height: AppMetrics.sp4),
          SoftCard(
            tone: AppColors.brand050,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        AppStrings.pickupCodeLabel,
                        style: TextStyle(
                          fontSize: AppMetrics.tiny,
                          color: AppColors.ink500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _pickupCode,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                          color: AppColors.brand700,
                        ),
                      ),
                    ],
                  ),
                ),
                QuietButton(
                  label: AppStrings.copyPickupCode,
                  icon: AppIcons.copy,
                  onPressed: () => copyWithNotice(context, _pickupCode),
                ),
              ],
            ),
          ),
        ],
        if (_courses.isNotEmpty) ...[
          const SizedBox(height: AppMetrics.sp4),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CardHeading(
                  title: AppStrings.recognizedCourses,
                  subtitle: '先核对一遍，再保存到课表。',
                  action: PrimaryButton(
                    label: AppStrings.saveToSchedule,
                    onPressed: _save,
                  ),
                ),
                const SizedBox(height: AppMetrics.sp4),
                for (final course in _courses)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppMetrics.sp2),
                    child: CoursePreviewTile(course: course),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ============================================================
// 取件码
// ============================================================
class PickupImportSection extends StatefulWidget {
  const PickupImportSection({super.key});

  @override
  State<PickupImportSection> createState() => _PickupImportSectionState();
}

class _PickupImportSectionState extends State<PickupImportSection> {
  final _controller = TextEditingController();
  bool _loading = false;
  String _error = '';
  List<Course>? _courses;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    final code = _controller.text.trim().toUpperCase();
    if (code.length != 8) {
      setState(() => _error = AppStrings.enterEightDigitPickupCode);
      return;
    }
    setState(() {
      _loading = true;
      _error = '';
      _courses = null;
    });
    try {
      final courses = await ClarkBackendApi.instance.getCoursesByPickupCode(
        code,
      );
      if (!mounted) {
        return;
      }
      setState(() => _courses = courses);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(
        () => _error = error is ApiException
            ? error.message
            : AppStrings.pickupCodeImportFailed,
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _save() async {
    final courses = _courses;
    if (courses == null || courses.isEmpty) {
      return;
    }
    final store = ScheduleScope.of(context);
    final outcome = await store.importCourses(courses);
    if (!mounted) {
      return;
    }
    AppNotice.success(
      context,
      outcome.changed ? AppStrings.coursesImported : AppStrings.importUnchanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final courses = _courses;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CardHeading(
                title: AppStrings.importByPickupCodeTitle,
                subtitle: AppStrings.importByPickupCodeSubtitle,
              ),
              const SizedBox(height: AppMetrics.sp4),
              TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: AppStrings.pickupCodeLabel,
                  hintText: AppStrings.pickupCodeHint,
                  errorText: _error.isEmpty ? null : _error,
                ),
                onSubmitted: (_) => _fetch(),
              ),
              const SizedBox(height: AppMetrics.sp4),
              PrimaryButton(
                label: _loading ? AppStrings.fetchingCourses : '取回这份课表',
                loading: _loading,
                onPressed: _fetch,
              ),
            ],
          ),
        ),
        if (courses != null) ...[
          const SizedBox(height: AppMetrics.sp4),
          if (courses.isEmpty)
            const SoftCard(
              child: EmptyPanel(
                title: AppStrings.pickupCodeNoCourses,
                body: AppStrings.pickupCodeNoCourses,
              ),
            )
          else
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CardHeading(
                    title: '取回 ${courses.length} 门课程',
                    subtitle: '存进课表后，这些课会和你原有的课放在一起。',
                    action: PrimaryButton(
                      label: AppStrings.saveToSchedule,
                      onPressed: _save,
                    ),
                  ),
                  const SizedBox(height: AppMetrics.sp4),
                  for (final course in courses)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppMetrics.sp2),
                      child: CoursePreviewTile(course: course),
                    ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}
