import 'package:flutter/material.dart';

import '../resources/app_colors.dart';
import '../resources/app_metrics.dart';
import '../resources/app_strings.dart';
import '../services/auth_session.dart';
import '../services/clark_backend_api.dart';
import '../widgets/app_icons.dart';
import '../widgets/feedback.dart';
import '../widgets/soft_ui.dart';

/// 账号页：登录、注册、查看账号状态。
///
/// 三种进入方式并列：QQ 邮箱 + 密码、登录码、注册新账号。
/// 不写"token""会话"这类词，用户只需要知道"用哪个能进去"。
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  String _mode = 'email';
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _username = TextEditingController();
  final _code = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String _error = '';

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _username.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = '';
    });

    try {
      final session = AuthSession.instance;
      switch (_mode) {
        case 'code':
          await session.loginByCode(_code.text.trim());
        case 'register':
          await session.register(
            username: _username.text.trim(),
            password: _password.text,
            qqEmail: _email.text.trim(),
          );
        default:
          await session.loginByEmail(
            qqEmail: _email.text.trim(),
            password: _password.text,
          );
      }
      if (mounted) {
        AppNotice.success(context, AppStrings.loggedIn);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error is ApiException
              ? error.message
              : AppStrings.requestFailed;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _logoutAll() async {
    final confirmed = await confirmDanger(
      context,
      title: AppStrings.logoutAllDevices,
      message: AppStrings.logoutAllHint,
      confirmLabel: AppStrings.logoutAllDevices,
    );
    if (!confirmed || !mounted) {
      return;
    }
    try {
      await AuthSession.instance.logoutAllDevices();
      if (mounted) {
        AppNotice.success(context, '旧登录码已失效，其它设备需要重新登录');
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = AppStrings.requestFailed);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text(AppStrings.accountTitle),
        leading: IconButton(
          icon: const Icon(AppIcons.close),
          tooltip: AppStrings.close,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: AuthSession.instance,
          builder: (context, _) {
            final user = AuthSession.instance.user;
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppMetrics.sp5,
                    AppMetrics.sp4,
                    AppMetrics.sp5,
                    AppMetrics.sp6,
                  ),
                  children: [
                    if (user.isAuthenticated)
                      _SignedInCard(onLogoutAll: _logoutAll, error: _error)
                    else ...[
                      _ModeTabs(
                        mode: _mode,
                        onChanged: (value) => setState(() {
                          _mode = value;
                          _error = '';
                        }),
                      ),
                      const SizedBox(height: AppMetrics.sp4),
                      Form(
                        key: _formKey,
                        child: SoftCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_mode == 'register') ...[
                                TextFormField(
                                  controller: _username,
                                  decoration: const InputDecoration(
                                    labelText: AppStrings.username,
                                    helperText: '登录时可以用用户名，也可以改用邮箱。',
                                  ),
                                  validator: (value) =>
                                      (value ?? '').trim().isEmpty
                                      ? AppStrings.fieldRequired
                                      : null,
                                ),
                                const SizedBox(height: AppMetrics.sp3),
                              ],
                              TextFormField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: AppStrings.qqEmail,
                                  helperText: '用来接收验证码，例如 123456789@qq.com',
                                ),
                                validator: (value) {
                                  final text = (value ?? '').trim();
                                  if (text.isEmpty) {
                                    return AppStrings.fieldRequired;
                                  }
                                  if (!text.contains('@') ||
                                      !text.contains('.')) {
                                    return AppStrings.enterQqEmail;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppMetrics.sp3),
                              TextFormField(
                                controller: _password,
                                obscureText: _obscure,
                                decoration: InputDecoration(
                                  labelText: AppStrings.password,
                                  helperText: '至少 6 位',
                                  suffixIcon: IconButton(
                                    tooltip: _obscure ? '显示密码' : '隐藏密码',
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      size: 20,
                                    ),
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                  ),
                                ),
                                validator: (value) => (value ?? '').length < 6
                                    ? '密码至少 6 位。'
                                    : null,
                              ),
                              if (_error.isNotEmpty) ...[
                                const SizedBox(height: AppMetrics.sp3),
                                NoticeBar(
                                  message: _error,
                                  tone: NoticeTone.error,
                                ),
                              ],
                              const SizedBox(height: AppMetrics.sp4),
                              PrimaryButton(
                                label: _mode == 'register'
                                    ? AppStrings.registerAndLogin
                                    : AppStrings.login,
                                loading: _busy,
                                expand: true,
                                onPressed: _submit,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (_mode == 'code' && !user.isAuthenticated) ...[
                      const SizedBox(height: AppMetrics.sp4),
                      SoftCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const CardHeading(
                              title: AppStrings.loginCode,
                              subtitle: '在另一台设备上打开「我的」就能看到登录码。',
                            ),
                            const SizedBox(height: AppMetrics.sp3),
                            TextFormField(
                              controller: _code,
                              decoration: const InputDecoration(
                                labelText: AppStrings.loginCode,
                                hintText: '8 位字母与数字',
                              ),
                            ),
                            const SizedBox(height: AppMetrics.sp4),
                            PrimaryButton(
                              label: AppStrings.login,
                              loading: _busy,
                              expand: true,
                              onPressed: _submit,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ModeTabs extends StatelessWidget {
  const _ModeTabs({required this.mode, required this.onChanged});

  final String mode;
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
          for (final (key, label) in const [
            ('email', AppStrings.emailLogin),
            ('code', AppStrings.loginCode),
            ('register', AppStrings.register),
          ])
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(key),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: AppMetrics.fast,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: mode == key ? AppColors.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppMetrics.rPill),
                    boxShadow: mode == key ? AppColors.shadowSm : null,
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppMetrics.small,
                      fontWeight: mode == key
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: mode == key
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

class _SignedInCard extends StatelessWidget {
  const _SignedInCard({required this.onLogoutAll, required this.error});

  final VoidCallback onLogoutAll;
  final String error;

  @override
  Widget build(BuildContext context) {
    final user = AuthSession.instance.user;
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
                      user.displayName,
                      style: const TextStyle(
                        fontSize: AppMetrics.body,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email.isEmpty ? AppStrings.notGenerated : user.email,
                      style: const TextStyle(
                        fontSize: AppMetrics.tiny,
                        color: AppColors.ink500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppMetrics.sp3),
          KvRow(
            label: AppStrings.emailStatus,
            value: user.emailVerified
                ? AppStrings.verified
                : AppStrings.unverified,
          ),
          KvRow(
            label: AppStrings.loginCode,
            value: user.maskedLoginCode,
            showDivider: false,
          ),
          const SizedBox(height: AppMetrics.sp3),
          Row(
            children: [
              QuietButton(
                label: AppStrings.logout,
                onPressed: () async {
                  await AuthSession.instance.logout();
                  if (context.mounted) {
                    AppNotice.show(context, AppStrings.loggedOut);
                  }
                },
              ),
              const SizedBox(width: AppMetrics.sp2),
              QuietButton(
                label: AppStrings.logoutAllDevices,
                onPressed: onLogoutAll,
              ),
            ],
          ),
          if (error.isNotEmpty) ...[
            const SizedBox(height: AppMetrics.sp3),
            NoticeBar(message: error, tone: NoticeTone.error),
          ],
        ],
      ),
    );
  }
}
