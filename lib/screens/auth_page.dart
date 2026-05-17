import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/clark_user.dart';
import '../resources/app_strings.dart';
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
          appBar: AppBar(title: const Text(AppStrings.accountTitle)),
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
      AppSnackBar.show(context, AppStrings.loggedIn);
    } on ApiException catch (error) {
      _showError(error.message);
    } catch (error) {
      _showError(AppStrings.requestFailed(error));
    }
  }

  Future<void> _logout() async {
    try {
      await AuthSession.instance.logout();
      if (!mounted) {
        return;
      }
      AppSnackBar.show(context, AppStrings.loggedOut);
    } catch (error) {
      _showError(AppStrings.logoutFailed(error));
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
            AppStrings.loginForChaoxing,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            AppStrings.loginOptionalDescription,
            style: TextStyle(
              color: Color(0xff81799f),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          SegmentedButton<_AuthMode>(
            segments: const [
              ButtonSegment(
                value: _AuthMode.emailLogin,
                label: Text(AppStrings.emailLogin),
              ),
              ButtonSegment(
                value: _AuthMode.codeLogin,
                label: Text(AppStrings.loginCode),
              ),
              ButtonSegment(
                value: _AuthMode.register,
                label: Text(AppStrings.register),
              ),
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
                labelText: AppStrings.username,
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
                labelText: AppStrings.qqEmail,
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
                labelText: AppStrings.password,
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
                labelText: AppStrings.loginCode,
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
              label: Text(
                mode == _AuthMode.register
                    ? AppStrings.registerAndLogin
                    : AppStrings.login,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.fieldRequired;
    }
    return null;
  }

  static String? _emailValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return AppStrings.enterQqEmail;
    }
    if (!text.endsWith('@qq.com')) {
      return AppStrings.useQqEmail;
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
        _AccountLine(label: AppStrings.loginCode, value: user.maskedLoginCode),
        _AccountLine(
          label: AppStrings.emailStatus,
          value: user.emailVerified
              ? AppStrings.verified
              : AppStrings.unverified,
        ),
        _AccountLine(
          label: AppStrings.questionAnalysisCount,
          value: '${user.questionAnalysisCount}',
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: user.loginCode.isEmpty
                    ? null
                    : () {
                        Clipboard.setData(ClipboardData(text: user.loginCode));
                        AppSnackBar.show(context, AppStrings.loginCodeCopied);
                      },
                icon: const Icon(Icons.copy),
                label: const Text(AppStrings.copyLoginCode),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: busy ? null : onLogout,
                icon: const Icon(Icons.logout),
                label: const Text(AppStrings.logout),
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
