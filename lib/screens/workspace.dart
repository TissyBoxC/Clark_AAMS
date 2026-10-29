import 'package:flutter/material.dart';

import '../models/course.dart';
import '../resources/app_colors.dart';
import '../resources/app_metrics.dart';
import '../resources/app_strings.dart';
import '../services/auth_session.dart';
import '../services/schedule_scope.dart';
import '../services/schedule_utils.dart';
import '../widgets/app_icons.dart';
import '../widgets/course_tile.dart';
import '../widgets/feedback.dart';
import '../widgets/soft_ui.dart';
import 'auth_page.dart';
import 'course_editor.dart';
import 'import_page.dart';
import 'questions_page.dart';
import 'schedule_page.dart';
import 'settings_page.dart';

/// 页签切换的入口，供页面深处的按钮跳转使用。
class WorkspaceTabs extends InheritedWidget {
  const WorkspaceTabs({required this.select, required super.child, super.key});

  final ValueChanged<int> select;

  static void go(BuildContext context, int index) {
    context.dependOnInheritedWidgetOfExactType<WorkspaceTabs>()?.select(index);
  }

  @override
  bool updateShouldNotify(WorkspaceTabs oldWidget) =>
      select != oldWidget.select;
}

/// 工作台骨架：手机底部四个页签，宽屏侧边栏。
///
/// 一个页面组件同时服务手机与桌面：窄屏堆叠、宽屏分栏，
/// 不在两处维护两份界面。
class WorkspaceShell extends StatefulWidget {
  const WorkspaceShell({super.key});

  @override
  State<WorkspaceShell> createState() => _WorkspaceShellState();
}

class _WorkspaceShellState extends State<WorkspaceShell> {
  int _index = 0;

  static const _destinations = <_Destination>[
    _Destination(
      label: AppStrings.homeTab,
      icon: AppIcons.home,
      activeIcon: AppIcons.homeActive,
    ),
    _Destination(
      label: AppStrings.scheduleTab,
      icon: AppIcons.schedule,
      activeIcon: AppIcons.scheduleActive,
    ),
    _Destination(
      label: AppStrings.importTab,
      icon: AppIcons.import,
      activeIcon: AppIcons.importActive,
    ),
    _Destination(
      label: AppStrings.practiceTab,
      icon: AppIcons.practice,
      activeIcon: AppIcons.practiceActive,
    ),
    _Destination(
      label: AppStrings.mineTab,
      icon: AppIcons.mine,
      activeIcon: AppIcons.mineActive,
    ),
  ];

  static const _pages = <Widget>[
    HomeOverviewPage(),
    SchedulePage(),
    ImportPage(),
    QuestionsPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 900;

    return WorkspaceTabs(
      select: (value) => setState(() => _index = value),
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          child: Row(
            children: [
              if (wide)
                _SideRail(
                  index: _index,
                  destinations: _destinations,
                  onSelected: (value) => setState(() => _index = value),
                ),
              Expanded(
                child: IndexedStack(index: _index, children: _pages),
              ),
            ],
          ),
        ),
        bottomNavigationBar: wide
            ? null
            : _BottomBar(
                index: _index,
                destinations: _destinations,
                onSelected: (value) => setState(() => _index = value),
              ),
      ),
    );
  }
}

class _Destination {
  const _Destination({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.index,
    required this.destinations,
    required this.onSelected,
  });

  final int index;
  final List<_Destination> destinations;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      child: Row(
        children: [
          for (var i = 0; i < destinations.length; i++)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(AppMetrics.rMd),
                onTap: () => onSelected(i),
                child: AnimatedContainer(
                  duration: AppMetrics.fast,
                  curve: AppMetrics.ease,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: i == index ? AppColors.brand050 : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppMetrics.rMd),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        i == index
                            ? destinations[i].activeIcon
                            : destinations[i].icon,
                        size: 22,
                        color: i == index
                            ? AppColors.brand700
                            : AppColors.ink400,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        destinations[i].label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: i == index
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: i == index
                              ? AppColors.brand700
                              : AppColors.ink500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SideRail extends StatelessWidget {
  const _SideRail({
    required this.index,
    required this.destinations,
    required this.onSelected,
  });

  final int index;
  final List<_Destination> destinations;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 232,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.line)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppMetrics.sp4,
        AppMetrics.sp5,
        AppMetrics.sp4,
        AppMetrics.sp4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.brand600,
                  borderRadius: BorderRadius.circular(AppMetrics.rSm),
                ),
                child: const Text(
                  '珂',
                  style: TextStyle(
                    color: AppColors.inkInverse,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppMetrics.sp3),
              const Expanded(
                child: Text(
                  AppStrings.appName,
                  style: TextStyle(
                    fontSize: AppMetrics.body,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppMetrics.sp6),
          for (var i = 0; i < destinations.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _RailItem(
                destination: destinations[i],
                selected: i == index,
                onTap: () => onSelected(i),
              ),
            ),
          const Spacer(),
          const _AccountHint(),
        ],
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _Destination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.brand100 : Colors.transparent,
      borderRadius: BorderRadius.circular(AppMetrics.rMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppMetrics.rMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppMetrics.sp3,
            vertical: 11,
          ),
          child: Row(
            children: [
              Icon(
                selected ? destination.activeIcon : destination.icon,
                size: 20,
                color: selected ? AppColors.brand700 : AppColors.ink500,
              ),
              const SizedBox(width: AppMetrics.sp3),
              Text(
                destination.label,
                style: TextStyle(
                  fontSize: AppMetrics.small,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? AppColors.brand700 : AppColors.ink700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountHint extends StatelessWidget {
  const _AccountHint();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AuthSession.instance,
      builder: (context, _) {
        final user = AuthSession.instance.user;
        return Container(
          padding: const EdgeInsets.all(AppMetrics.sp3),
          decoration: BoxDecoration(
            color: AppColors.surfaceSunken,
            borderRadius: BorderRadius.circular(AppMetrics.rMd),
          ),
          child: Row(
            children: [
              InitialAvatar(name: user.displayName, size: 32),
              const SizedBox(width: AppMetrics.sp2),
              Expanded(
                child: Text(
                  user.isAuthenticated
                      ? user.displayName
                      : AppStrings.notLoggedIn,
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
        );
      },
    );
  }
}

// ============================================================
// 首页概览
// ============================================================
class HomeOverviewPage extends StatelessWidget {
  const HomeOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ScheduleScope.of(context);
    final settings = store.settings;
    final all = store.courses;
    final now = DateTime.now();
    final week = ScheduleUtils.currentWeek(settings, now);
    final today =
        all
            .where(
              (course) =>
                  course.matchesWeek(week) && course.dayOfWeek == now.weekday,
            )
            .toList()
          ..sort((a, b) => a.startLesson.compareTo(b.startLesson));

    return PageScaffold(
      title: AppStrings.homeHeroTitle,
      description: AppStrings.homeHeroSubtitle(
        AppStrings.homeWeekLabel(week),
        today.length,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 760;
          final cards = [
            _StatCard(
              label: AppStrings.courseCount,
              value: '${all.length}',
              hint: '整学期一共这么多门课',
            ),
            _StatCard(
              label: AppStrings.currentWeekLabel,
              value: AppStrings.weekNumber(week),
              hint: AppStrings.homeWeekLabel(week),
            ),
            const _StatCard(
              label: AppStrings.todayCourses,
              value: '',
              hint: '',
            ),
          ];
          if (!wide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final card in cards.take(2))
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppMetrics.sp3),
                    child: card,
                  ),
                _TodayList(courses: today, total: all.length),
                const SizedBox(height: AppMetrics.sp4),
                const _TipCard(),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 300,
                child: Column(
                  children: [
                    for (final card in cards.take(2))
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppMetrics.sp3),
                        child: card,
                      ),
                    const _TipCard(),
                  ],
                ),
              ),
              const SizedBox(width: AppMetrics.sp4),
              Expanded(
                child: _TodayList(courses: today, total: all.length),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.hint,
  });

  final String label;
  final String value;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(AppMetrics.sp4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: AppMetrics.tiny,
              color: AppColors.ink500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.ink900,
            ),
          ),
          if (hint.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              hint,
              style: const TextStyle(
                fontSize: AppMetrics.tiny,
                color: AppColors.ink400,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TodayList extends StatelessWidget {
  const _TodayList({required this.courses, required this.total});

  final List<Course> courses;
  final int total;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardHeading(
            title: AppStrings.todayCourses,
            subtitle: courses.isEmpty
                ? (total == 0
                      ? AppStrings.noCoursesYet
                      : AppStrings.noCoursesToday)
                : '今天共 ${courses.length} 节课，按时间排好了。',
          ),
          const SizedBox(height: AppMetrics.sp3),
          if (courses.isEmpty)
            EmptyPanel(
              title: total == 0
                  ? AppStrings.emptyScheduleTitle
                  : AppStrings.noCoursesToday,
              body: total == 0
                  ? AppStrings.emptyScheduleCopy
                  : AppStrings.coursesFinishedToday,
            )
          else
            for (final course in courses)
              Padding(
                padding: const EdgeInsets.only(bottom: AppMetrics.sp2),
                child: CourseTile(
                  course: course,
                  onTap: () => showCourseEditor(context, course: course),
                ),
              ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard();

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      sunken: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '这节课的时间是怎么算的',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.ink900,
            ),
          ),
          const SizedBox(height: AppMetrics.sp2),
          const HintText(
            '课表按每节课的开始时间往后推一节时长。学校作息不同的话，'
            '在「设置 → 学期与作息」里改一次，整张课表都会跟着更新。',
          ),
          const SizedBox(height: AppMetrics.sp3),
          TextButton(
            onPressed: () => WorkspaceTabs.go(context, 4),
            child: const Text('去调整上课时间'),
          ),
        ],
      ),
    );
  }
}

/// 打开登录页的便捷入口（设置页与账号卡共用）。
Future<void> openAccountPage(BuildContext context) {
  return Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const AuthPage()));
}

/// 空课表引导跳转到导入页。
void goToImportTab(BuildContext context) => WorkspaceTabs.go(context, 2);
