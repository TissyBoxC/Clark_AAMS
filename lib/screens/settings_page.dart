import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../models/app_settings.dart';
import '../resources/app_colors.dart';
import '../resources/app_metrics.dart';
import '../resources/app_strings.dart';
import '../services/auth_session.dart';
import '../services/clark_backend_api.dart';
import '../services/lesson_time_defaults.dart';
import '../services/schedule_scope.dart';
import '../services/schedule_utils.dart';
import '../widgets/app_icons.dart';
import '../widgets/feedback.dart';
import '../widgets/soft_ui.dart';
import 'auth_page.dart';
import 'course_settings_page.dart';
import 'term_setup_page.dart';

/// 我的 / 设置页。
///
/// 手机端叫「我的」，宽屏侧栏叫「设置」，同一个页面两处入口。
/// 结构按"账号 → 学期 → 提示 → 关于"排，重要的事在上面。
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _version = '${info.version}+${info.buildNumber}');
      }
    } catch (_) {
      // 读不到版本号不影响其它设置。
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = ScheduleScope.of(context);
    final settings = store.settings;

    return PageScaffold(
      title: AppStrings.mineTab,
      description: '账号、学期作息与提醒都在这一页。',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AccountCard(onOpenAccount: () => _openAccount()),
          const SizedBox(height: AppMetrics.sp4),
          _TermCard(settings: settings),
          const SizedBox(height: AppMetrics.sp4),
          _ActionGrid(
            settings: settings,
            onOpenCourseSettings: _openCourseSettings,
            onOpenTermSetup: _openTermSetup,
          ),
          const SizedBox(height: AppMetrics.sp4),
          _AboutCard(version: _version),
        ],
      ),
    );
  }

  Future<void> _openAccount() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const AuthPage()));
  }

  Future<void> _openCourseSettings() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const CourseSettingsPage()));
  }

  Future<void> _openTermSetup() async {
    final store = ScheduleScope.of(context);
    final defaults = await LessonTimeDefaults.resolve(
      store,
      courses: store.courses,
    );
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => TermSetupPage(
          initialStartTimes: defaults.initialStartTimes,
          initialTermStartDate: ScheduleUtils.termStartDate(store.settings),
          lessonCount: ScheduleUtils.lessonCount(store.settings, store.courses),
          profiles: defaults.generalProfiles,
          notice: defaults.notice,
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.onOpenAccount});

  final VoidCallback onOpenAccount;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AuthSession.instance,
      builder: (context, _) {
        final session = AuthSession.instance;
        final user = session.user;

        return SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  InitialAvatar(name: user.displayName, size: 48),
                  const SizedBox(width: AppMetrics.sp3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.isAuthenticated
                              ? user.displayName
                              : AppStrings.notLoggedIn,
                          style: const TextStyle(
                            fontSize: AppMetrics.body,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.isAuthenticated
                              ? (user.emailVerified
                                    ? AppStrings.emailVerifiedNotice
                                    : AppStrings.emailUnverifiedNotice)
                              : '登录后课表会跟着账号走，换手机也能看到。',
                          style: const TextStyle(
                            fontSize: AppMetrics.tiny,
                            height: 1.6,
                            color: AppColors.ink500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (user.isAuthenticated) ...[
                const SizedBox(height: AppMetrics.sp3),
                const Divider(height: 1),
                KvRow(
                  label: AppStrings.emailStatus,
                  value: user.emailVerified
                      ? AppStrings.verified
                      : AppStrings.unverified,
                ),
                KvRow(
                  label: AppStrings.questionAnalysisCount,
                  value: '${user.questionAnalysisCount}',
                ),
                KvRow(
                  label: AppStrings.loginCode,
                  value: user.maskedLoginCode,
                  showDivider: false,
                  trailing: IconButton(
                    tooltip: AppStrings.copyLoginCode,
                    icon: const Icon(AppIcons.copy, size: 18),
                    onPressed: () async {
                      if (user.loginCode.isEmpty) {
                        return;
                      }
                      await Clipboard.setData(
                        ClipboardData(text: user.loginCode),
                      );
                      if (context.mounted) {
                        AppNotice.success(context, AppStrings.loginCodeCopied);
                      }
                    },
                  ),
                ),
              ],
              const SizedBox(height: AppMetrics.sp3),
              Row(
                children: [
                  if (!user.isAuthenticated)
                    PrimaryButton(label: '登录或注册', onPressed: onOpenAccount)
                  else ...[
                    QuietButton(
                      label: AppStrings.accountTitle,
                      onPressed: onOpenAccount,
                    ),
                    const SizedBox(width: AppMetrics.sp2),
                    QuietButton(
                      label: AppStrings.logout,
                      onPressed: () async {
                        await AuthSession.instance.logout();
                        if (context.mounted) {
                          AppNotice.show(context, AppStrings.loggedOut);
                        }
                      },
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TermCard extends StatelessWidget {
  const _TermCard({required this.settings});

  final AppSettingsModel settings;

  @override
  Widget build(BuildContext context) {
    final configured = settings.startTimes.any(
      (time) => time.trim().isNotEmpty,
    );
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CardHeading(
            title: AppStrings.termAndLessonTimesTitle,
            subtitle: AppStrings.termAndLessonTimesSubtitle,
          ),
          const SizedBox(height: AppMetrics.sp3),
          KvRow(
            label: AppStrings.termFirstDayLabel,
            value: settings.termStartDate.isEmpty
                ? AppStrings.notSet
                : settings.termStartDate,
          ),
          KvRow(
            label: AppStrings.maxWeeksLabel,
            value: AppStrings.weekRangeText(1, settings.maxWeeks),
          ),
          KvRow(
            label: AppStrings.lessonTimesLabel,
            value: configured
                ? AppStrings.lessonTimesImportedForStart(
                    settings.startTimes.first,
                  )
                : AppStrings.notConfigured,
            showDivider: false,
          ),
          if (!configured) ...[
            const SizedBox(height: AppMetrics.sp3),
            const NoticeBar(
              message: '还没有填上课时间，课表上不会显示「几点到几点」。填一次就行，之后都能用。',
              tone: NoticeTone.warn,
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({
    required this.settings,
    required this.onOpenCourseSettings,
    required this.onOpenTermSetup,
  });

  final AppSettingsModel settings;
  final VoidCallback onOpenCourseSettings;
  final VoidCallback onOpenTermSetup;

  @override
  Widget build(BuildContext context) {
    final items = <_ActionItem>[
      _ActionItem(
        icon: AppIcons.schedule,
        title: AppStrings.courseSettingsTitle,
        subtitle: AppStrings.courseSettingsSubtitle,
        onTap: onOpenCourseSettings,
      ),
      _ActionItem(
        icon: AppIcons.clock,
        title: AppStrings.termAndLessonTimesTitle,
        subtitle: '开学日期与每节课的开始时间',
        onTap: onOpenTermSetup,
      ),
      _ActionItem(
        icon: AppIcons.school,
        title: AppStrings.schoolInfo,
        subtitle: settings.schoolId.isEmpty
            ? AppStrings.noSchoolSelected
            : settings.schoolId,
        onTap: () => AppNotice.show(context, '学校在「导入课表 → 教务导入」里切换。'),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 3 : 1;
        final spacing = AppMetrics.sp3;
        final width = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: SoftCard(
                  onTap: item.onTap,
                  padding: const EdgeInsets.all(AppMetrics.sp4),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.brand050,
                          borderRadius: BorderRadius.circular(AppMetrics.rMd),
                        ),
                        child: Icon(
                          item.icon,
                          size: 20,
                          color: AppColors.brand700,
                        ),
                      ),
                      const SizedBox(width: AppMetrics.sp3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: AppMetrics.body,
                                fontWeight: FontWeight.w500,
                                color: AppColors.ink900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: AppMetrics.tiny,
                                color: AppColors.ink500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        AppIcons.chevronRight,
                        size: 20,
                        color: AppColors.ink400,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ActionItem {
  const _ActionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

class _AboutCard extends StatefulWidget {
  const _AboutCard({required this.version});

  final String version;

  @override
  State<_AboutCard> createState() => _AboutCardState();
}

class _AboutCardState extends State<_AboutCard> {
  String _status = '';
  bool _checking = false;

  Future<void> _checkUpdate() async {
    setState(() {
      _checking = true;
      _status = AppStrings.checkingLatestVersion;
    });
    try {
      final info = await PackageInfo.fromPlatform();
      final latest = await ClarkBackendApi.instance.checkVersion(
        platform: 'android',
        currentVersion: info.version,
        currentBuild: int.tryParse(info.buildNumber),
        channel: 'stable',
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _status = latest.updateAvailable
            ? '${AppStrings.newVersionAvailable} · ${latest.latestVersion}'
            : AppStrings.alreadyLatestVersion;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _status = AppStrings.invalidVersionCheckResponse);
      }
    } finally {
      if (mounted) {
        setState(() => _checking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CardHeading(
            title: AppStrings.aboutTitle,
            subtitle: AppStrings.appDescription,
          ),
          const SizedBox(height: AppMetrics.sp3),
          KvRow(
            label: AppStrings.currentVersion,
            value: widget.version.isEmpty ? AppStrings.loading : widget.version,
            showDivider: false,
          ),
          if (_status.isNotEmpty) ...[
            const SizedBox(height: AppMetrics.sp2),
            HintText(_status),
          ],
          const SizedBox(height: AppMetrics.sp3),
          Align(
            alignment: Alignment.centerLeft,
            child: QuietButton(
              label: AppStrings.checkUpdate,
              icon: AppIcons.refresh,
              onPressed: _checking ? null : _checkUpdate,
            ),
          ),
        ],
      ),
    );
  }
}
