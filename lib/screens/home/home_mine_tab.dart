import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../resources/app_strings.dart';
import '../../services/auth_session.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/top_bar.dart';
import '../about_page.dart';
import '../app_settings_page.dart';
import '../auth_page.dart';
import '../chaoxing_homework_page.dart';
import '../course_settings_page.dart';
import 'home_style.dart';
import 'home_tab.dart' show SoftPanel;

/// 首页「我的」Tab：账户卡与功能入口。
class MineTab extends StatelessWidget {
  const MineTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TopBar(
          title: AppStrings.mineTab,
          trailing: AnimatedBuilder(
            animation: AuthSession.instance,
            builder: (context, _) => AuthEntryButton(
              authenticated: AuthSession.instance.isAuthenticated,
              label: AuthSession.instance.isAuthenticated
                  ? AuthSession.instance.user.displayName
                  : AppStrings.loginOrRegister,
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
            children: [
              const MineProfileCard(),
              const SizedBox(height: 14),
              MineActionTile(
                icon: Icons.widgets_outlined,
                title: AppStrings.homeWidgetTitle,
                subtitle: AppStrings.homeWidgetSubtitle,
                color: const Color(0xff6d64ff),
                onTap: _pinHomeWidget,
              ),
              MineActionTile(
                icon: Icons.school_outlined,
                title: AppStrings.chaoxingHomeworkTitle,
                subtitle: AppStrings.chaoxingHomeworkSubtitle,
                color: homePink,
                onTap: _openChaoxingHomework,
              ),
              const MineActionTile(
                icon: Icons.edit_calendar_outlined,
                title: AppStrings.courseSettingsTitle,
                subtitle: AppStrings.courseSettingsSubtitle,
                color: homeLavender,
                page: CourseSettingsPage(),
              ),
              const MineActionTile(
                icon: Icons.settings_outlined,
                title: AppStrings.appSettingsTitle,
                subtitle: AppStrings.appSettingsSubtitle,
                color: Color(0xff5bb6ff),
                page: AppSettingsPage(),
              ),
              const MineActionTile(
                icon: Icons.info_outline,
                title: AppStrings.aboutTitle,
                subtitle: AppStrings.aboutSubtitle,
                color: Color(0xffffc45b),
                page: AboutPage(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Future<void> _pinHomeWidget(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(AppStrings.addWidgetTitle),
          content: const Text(AppStrings.addWidgetManualMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(AppStrings.close),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await launchUrl(
                  Uri.parse('https://clarkhub.cn'),
                  mode: LaunchMode.externalApplication,
                );
              },
              child: const Text(AppStrings.openWebsite),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _openChaoxingHomework(BuildContext context) async {
    final session = AuthSession.instance;
    if (session.isAuthenticated) {
      try {
        await session.refresh();
      } catch (_) {
        // 保留本地状态，让后端在实际请求时再做校验。
      }
    }
    if (!context.mounted) {
      return;
    }
    if (!session.isAuthenticated) {
      AppSnackBar.show(
        context,
        AppStrings.chaoxingLoginRequiredFromHome,
        action: SnackBarAction(
          label: AppStrings.goLogin,
          onPressed: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const AuthPage()));
          },
        ),
      );
      return;
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ChaoxingHomeworkPage()));
  }
}

class AuthEntryButton extends StatelessWidget {
  const AuthEntryButton({
    required this.authenticated,
    required this.label,
    super.key,
  });

  final bool authenticated;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AuthPage()));
      },
      icon: Icon(authenticated ? Icons.account_circle : Icons.login, size: 18),
      label: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 82),
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      style: TextButton.styleFrom(
        foregroundColor: homeLavender,
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }
}

class MineProfileCard extends StatelessWidget {
  const MineProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SoftPanel(
      padding: const EdgeInsets.fromLTRB(18, 12, 10, 10),
      child: Row(
        children: [
          Expanded(
            child: AnimatedBuilder(
              animation: AuthSession.instance,
              builder: (context, _) {
                final user = AuthSession.instance.user;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      AppStrings.mineSpace,
                      style: TextStyle(
                        color: homeInk,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user.isAuthenticated
                          ? AppStrings.mineUsage(
                              user.displayName,
                              user.questionAnalysisCount,
                            )
                          : AppStrings.mineGuestSubtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: homeMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          AnimatedBuilder(
            animation: AuthSession.instance,
            builder: (context, _) =>
                MineAvatar(email: AuthSession.instance.user.email),
          ),
        ],
      ),
    );
  }
}

class MineAvatar extends StatelessWidget {
  const MineAvatar({required this.email, super.key});

  final String email;

  @override
  Widget build(BuildContext context) {
    final uin = _qqUin(email);
    if (uin == null) {
      return Image(
        image: const AssetImage('assets/nav/nav_mine_active.png'),
        width: 132,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      );
    }
    return Container(
      width: 92,
      height: 92,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: homeLine, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x180b0550),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.network(
          'https://q1.qlogo.cn/g?b=qq&nk=$uin&s=640',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(
              'assets/nav/nav_mine_active.png',
              fit: BoxFit.contain,
            );
          },
        ),
      ),
    );
  }

  static String? _qqUin(String email) {
    final normalized = email.trim().toLowerCase();
    if (!normalized.endsWith('@qq.com')) {
      return null;
    }
    final value = normalized.substring(0, normalized.length - 7);
    return RegExp(r'^\d{5,12}$').hasMatch(value) ? value : null;
  }
}

class MineActionTile extends StatelessWidget {
  const MineActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.page,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Widget? page;
  final Future<void> Function(BuildContext context)? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SoftPanel(
        padding: EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              final customTap = onTap;
              if (customTap != null) {
                customTap(context);
                return;
              }
              final target = page;
              if (target != null) {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => target));
              }
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color.withAlpha(34),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: homeInk,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: homeMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: homeMuted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
