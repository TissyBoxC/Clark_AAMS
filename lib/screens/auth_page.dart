import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/clark_user.dart';
import '../services/auth_session.dart';
import '../services/clark_backend_api.dart';
import '../widgets/app_snack_bar.dart';

enum _AuthMode { emailLogin, codeLogin, register }

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _loginCodeController = TextEditingController();
  _AuthMode _mode = _AuthMode.emailLogin;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _loginCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AuthSession.instance,
      builder: (context, _) {
        final session = AuthSession.instance;
        return Scaffold(
          appBar: AppBar(title: const Text('账号')),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
              children: [
                if (session.isAuthenticated)
                  _UserPanel(
                    user: session.user,
                    busy: session.busy,
                    onLogout: _logout,
                  )
                else
                  _AuthForm(
                    formKey: _formKey,
                    mode: _mode,
                    busy: session.busy,
                    emailController: _emailController,
                    passwordController: _passwordController,
                    usernameController: _usernameController,
                    loginCodeController: _loginCodeController,
                    onModeChanged: (mode) => setState(() => _mode = mode),
                    onSubmit: _submit,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    try {
      final session = AuthSession.instance;
      switch (_mode) {
        case _AuthMode.emailLogin:
          await session.loginByEmail(
            qqEmail: _emailController.text.trim(),
            password: _passwordController.text,
          );
          break;
        case _AuthMode.codeLogin:
          await session.loginByCode(_loginCodeController.text.trim());
          break;
        case _AuthMode.register:
          await session.register(
            username: _usernameController.text.trim(),
            password: _passwordController.text,
            qqEmail: _emailController.text.trim(),
          );
          break;
      }
      if (!mounted) {
        return;
      }
      AppSnackBar.show(context, '已登录');
    } on ApiException catch (error) {
      _showError(error.message);
    } catch (error) {
      _showError('请求失败：$error');
    }
  }

  Future<void> _logout() async {
    try {
      await AuthSession.instance.logout();
      if (!mounted) {
        return;
      }
      AppSnackBar.show(context, '已退出登录');
    } catch (error) {
      _showError('退出登录失败：$error');
    }
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    AppSnackBar.show(context, message);
  }
}

class _AuthForm extends StatelessWidget {
  const _AuthForm({
    required this.formKey,
    required this.mode,
    required this.busy,
    required this.emailController,
    required this.passwordController,
    required this.usernameController,
    required this.loginCodeController,
    required this.onModeChanged,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final _AuthMode mode;
  final bool busy;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController usernameController;
  final TextEditingController loginCodeController;
  final ValueChanged<_AuthMode> onModeChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '登录后可使用学习通作业辅助',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            '课表、桌面小组件等功能仍可不登录使用。',
            style: TextStyle(
              color: Color(0xff81799f),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          SegmentedButton<_AuthMode>(
            segments: const [
              ButtonSegment(value: _AuthMode.emailLogin, label: Text('邮箱登录')),
              ButtonSegment(value: _AuthMode.codeLogin, label: Text('登录码')),
              ButtonSegment(value: _AuthMode.register, label: Text('注册')),
            ],
            selected: {mode},
            onSelectionChanged: busy
                ? null
                : (value) => onModeChanged(value.single),
          ),
          const SizedBox(height: 18),
          if (mode == _AuthMode.register)
            TextFormField(
              controller: usernameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: '用户名',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: _required,
            ),
          if (mode == _AuthMode.register) const SizedBox(height: 12),
          if (mode != _AuthMode.codeLogin)
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'QQ 邮箱',
                prefixIcon: Icon(Icons.mail_outline),
                border: OutlineInputBorder(),
              ),
              validator: _emailValidator,
            ),
          if (mode != _AuthMode.codeLogin) const SizedBox(height: 12),
          if (mode != _AuthMode.codeLogin)
            TextFormField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '密码',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
              ),
              validator: _required,
              onFieldSubmitted: (_) => busy ? null : onSubmit(),
            ),
          if (mode == _AuthMode.codeLogin)
            TextFormField(
              controller: loginCodeController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: '登录码',
                prefixIcon: Icon(Icons.key_outlined),
                border: OutlineInputBorder(),
              ),
              validator: _required,
              onFieldSubmitted: (_) => busy ? null : onSubmit(),
            ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: busy ? null : onSubmit,
              icon: busy
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onPrimary,
                      ),
                    )
                  : const Icon(Icons.login),
              label: Text(mode == _AuthMode.register ? '注册并登录' : '登录'),
            ),
          ),
        ],
      ),
    );
  }

  static String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '不能为空';
    }
    return null;
  }

  static String? _emailValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return '请输入 QQ 邮箱';
    }
    if (!text.endsWith('@qq.com')) {
      return '请使用 QQ 邮箱';
    }
    return null;
  }
}

class _UserPanel extends StatelessWidget {
  const _UserPanel({
    required this.user,
    required this.busy,
    required this.onLogout,
  });

  final ClarkUser user;
  final bool busy;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user.displayName,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          user.email,
          style: const TextStyle(
            color: Color(0xff81799f),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 18),
        _AccountLine(label: '登录码', value: user.maskedLoginCode),
        _AccountLine(label: '邮箱状态', value: user.emailVerified ? '已认定' : '未认定'),
        _AccountLine(label: '做题辅助次数', value: '${user.questionAnalysisCount}'),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: user.loginCode.isEmpty
                    ? null
                    : () {
                        Clipboard.setData(ClipboardData(text: user.loginCode));
                        AppSnackBar.show(context, '登录码已复制');
                      },
                icon: const Icon(Icons.copy),
                label: const Text('复制登录码'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: busy ? null : onLogout,
                icon: const Icon(Icons.logout),
                label: const Text('退出登录'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AccountLine extends StatelessWidget {
  const _AccountLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xff81799f),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
