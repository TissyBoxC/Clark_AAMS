import 'package:flutter/material.dart';

import '../models/school.dart';
import '../services/schedule_scope.dart';
import 'course_settings_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  School _selectedSchool = SchoolCatalog.jit;

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
                '选择学校',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                '请选择当前使用的教务系统，后续可继续添加其他学校适配。',
                style: TextStyle(color: Color(0xff808080)),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: SchoolCatalog.schools.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final school = SchoolCatalog.schools[index];
                    final selected = school.id == _selectedSchool.id;
                    return _SchoolTile(
                      school: school,
                      selected: selected,
                      onTap: () => setState(() => _selectedSchool = school),
                    );
                  },
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    await store.selectSchool(_selectedSchool.id);
                    if (context.mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const CourseSettingsPage(),
                        ),
                      );
                    }
                  },
                  child: const Text('进入课程导入'),
                ),
              ),
            ],
          ),
        ),
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
                          ? '已配置教务系统导入'
                          : '暂未配置教务系统导入',
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
