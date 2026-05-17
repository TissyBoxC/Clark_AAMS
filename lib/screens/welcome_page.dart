import 'package:flutter/material.dart';

import '../models/school.dart';
import '../resources/app_strings.dart';
import '../services/clark_backend_api.dart';
import '../services/schedule_scope.dart';
import 'course_settings_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  late Future<List<School>> _schoolsFuture;
  final TextEditingController _searchController = TextEditingController();
  School? _selectedSchool;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _schoolsFuture = ClarkBackendApi.instance.getSchools();
    _searchController.addListener(() {
      setState(() => _searchText = _searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ScheduleScope.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                AppStrings.chooseSchoolTitle,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                AppStrings.chooseSchoolSubtitle,
                style: TextStyle(color: Color(0xff808080)),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: AppStrings.searchSchoolHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchText.isEmpty
                      ? null
                      : IconButton(
                          tooltip: AppStrings.clearSearch,
                          icon: const Icon(Icons.close),
                          onPressed: _searchController.clear,
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: FutureBuilder<List<School>>(
                  future: _schoolsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return _LoadError(
                        message: AppStrings.schoolListLoadFailed(
                          snapshot.error!,
                        ),
                        onRetry: _reloadSchools,
                      );
                    }

                    final schools = snapshot.data ?? const <School>[];
                    if (schools.isEmpty) {
                      return _LoadError(
                        message: AppStrings.noSchoolsFromBackend,
                        onRetry: _reloadSchools,
                      );
                    }

                    final visibleSchools = _filterSchools(schools);
                    if (visibleSchools.isEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && _selectedSchool != null) {
                          setState(() => _selectedSchool = null);
                        }
                      });
                      return const _EmptySearchResult();
                    }

                    final selected = _selectedSchool;
                    if (selected == null ||
                        !visibleSchools.any(
                          (school) => school.id == selected.id,
                        )) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(
                            () => _selectedSchool = visibleSchools.first,
                          );
                        }
                      });
                    }

                    return ListView.separated(
                      itemCount: visibleSchools.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final school = visibleSchools[index];
                        final selected = school.id == _selectedSchool?.id;
                        return _SchoolTile(
                          school: school,
                          selected: selected,
                          onTap: () => setState(() => _selectedSchool = school),
                        );
                      },
                    );
                  },
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _selectedSchool == null
                      ? null
                      : () async {
                          await store.selectSchool(_selectedSchool!.id);
                          if (context.mounted) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const CourseSettingsPage(),
                              ),
                            );
                          }
                        },
                  child: const Text(AppStrings.enterCourseImport),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    await store.useOtherImportMethods();
                    if (context.mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const CourseSettingsPage(),
                        ),
                      );
                    }
                  },
                  child: const Text(AppStrings.useOtherImportMethods),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<School> _filterSchools(List<School> schools) {
    final keyword = _searchText.toLowerCase();
    if (keyword.isEmpty) {
      return schools;
    }
    return [
      for (final school in schools)
        if (school.name.toLowerCase().contains(keyword) ||
            school.shortName.toLowerCase().contains(keyword) ||
            school.id.toLowerCase().contains(keyword))
          school,
    ];
  }

  void _reloadSchools() {
    setState(() {
      _selectedSchool = null;
      _schoolsFuture = ClarkBackendApi.instance.getSchools();
    });
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xff808080)),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text(AppStrings.chaoxingReload),
          ),
        ],
      ),
    );
  }
}

class _EmptySearchResult extends StatelessWidget {
  const _EmptySearchResult();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        AppStrings.noMatchedSchool,
        style: TextStyle(color: Color(0xff808080)),
      ),
    );
  }
}

class _SchoolTile extends StatelessWidget {
  const _SchoolTile({
    required this.school,
    required this.selected,
    required this.onTap,
  });

  final School school;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xffe9f1fb) : const Color(0xfff5f5f5),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xff3174f1),
                foregroundColor: Colors.white,
                child: Text(school.shortName),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${school.name}(${school.shortName})',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      school.supportsAcademicImport
                          ? AppStrings.academicImportConfigured
                          : AppStrings.academicImportNotYetConfigured,
                      style: const TextStyle(color: Color(0xff808080)),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected
                    ? const Color(0xff3174f1)
                    : const Color(0xffb0b0b0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
