import 'package:flutter/foundation.dart';

import '../models/clark_user.dart';
import '../widget/widget_service.dart';
import 'auth_token_store.dart';
import 'clark_backend_api.dart';

class AuthSession extends ChangeNotifier {
  AuthSession._();

  static final AuthSession instance = AuthSession._();

  ClarkUser _user = ClarkUser.empty;
  bool _initialized = false;
  bool _busy = false;

  ClarkUser get user => _user;
  bool get initialized => _initialized;
  bool get busy => _busy;
  bool get isAuthenticated => _user.isAuthenticated;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _setBusy(true);
    try {
      final loginCode = await AuthTokenStore.instance.readLoginCode();
      if (loginCode.isEmpty) {
        _user = ClarkUser.empty;
      } else {
        _user = await ClarkBackendApi.instance.currentUser();
        // 后端自 P0-4 起在 /user/me 不再回传登录码（避免凭据进入日志与缓存）。
        // 仅在返回了非空码时才覆盖本地缓存。
        if (_user.isAuthenticated && _user.loginCode.isNotEmpty) {
          await AuthTokenStore.instance.saveLoginCode(_user.loginCode);
        }
      }
    } catch (_) {
      _user = ClarkUser.empty;
    } finally {
      _initialized = true;
      _setBusy(false);
    }
  }

  Future<void> refresh() async {
    _setBusy(true);
    try {
      final loginCode = await AuthTokenStore.instance.readLoginCode();
      if (loginCode.isEmpty) {
        _user = ClarkUser.empty;
        return;
      }
      final user = await ClarkBackendApi.instance.currentUser();
      if (user.isAuthenticated) {
        _user = user;
        // 同上：/user/me 不回传登录码，空值不得覆盖本地缓存
        if (user.loginCode.isNotEmpty) {
          await AuthTokenStore.instance.saveLoginCode(user.loginCode);
        }
      } else if (!_user.isAuthenticated) {
        _user = ClarkUser.empty;
      }
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> hasUsableCredential() async {
    if (_user.isAuthenticated) {
      return true;
    }
    return (await AuthTokenStore.instance.readLoginCode()).isNotEmpty;
  }

  Future<AuthDebugSnapshot> debugSnapshot() async {
    return AuthDebugSnapshot(
      initialized: _initialized,
      busy: _busy,
      userId: _user.id,
      emailPresent: _user.email.isNotEmpty,
      userLoginCodePresent: _user.loginCode.isNotEmpty,
      tokenDiagnostics: await AuthTokenStore.instance.diagnostics(),
    );
  }

  Future<void> loginByEmail({
    required String qqEmail,
    required String password,
  }) async {
    _setBusy(true);
    try {
      final user = await ClarkBackendApi.instance.loginByEmail(
        qqEmail: qqEmail,
        password: password,
      );
      await _acceptUser(user);
    } finally {
      _setBusy(false);
    }
  }

  Future<void> loginByCode(String loginCode) async {
    _setBusy(true);
    try {
      final user = await ClarkBackendApi.instance.loginByCode(loginCode);
      await _acceptUser(user);
      if (user.loginCode.isEmpty) {
        await AuthTokenStore.instance.saveLoginCode(loginCode);
      }
    } finally {
      _setBusy(false);
    }
  }

  Future<void> register({
    required String username,
    required String password,
    required String qqEmail,
  }) async {
    _setBusy(true);
    try {
      final user = await ClarkBackendApi.instance.register(
        username: username,
        password: password,
        qqEmail: qqEmail,
      );
      await _acceptUser(user);
    } finally {
      _setBusy(false);
    }
  }

  Future<void> logout() async {
    _setBusy(true);
    try {
      await ClarkBackendApi.instance.logout();
    } finally {
      await AuthTokenStore.instance.clearLoginCode();
      _user = ClarkUser.empty;
      _setBusy(false);
      await WidgetService.updateWidget();
    }
  }

  Future<void> _acceptUser(ClarkUser user) async {
    _user = user;
    if (user.loginCode.isNotEmpty) {
      await AuthTokenStore.instance.saveLoginCode(user.loginCode);
    }
    await WidgetService.updateWidget();
  }

  void _setBusy(bool value) {
    if (_busy == value) {
      notifyListeners();
      return;
    }
    _busy = value;
    notifyListeners();
  }
}

class AuthDebugSnapshot {
  const AuthDebugSnapshot({
    required this.initialized,
    required this.busy,
    required this.userId,
    required this.emailPresent,
    required this.userLoginCodePresent,
    required this.tokenDiagnostics,
  });

  final bool initialized;
  final bool busy;
  final int userId;
  final bool emailPresent;
  final bool userLoginCodePresent;
  final AuthTokenDiagnostics tokenDiagnostics;

  List<String> toLogLines(String prefix) {
    return [
      '$prefix session initialized=$initialized busy=$busy userId=$userId emailPresent=$emailPresent userLoginCodePresent=$userLoginCodePresent',
      '$prefix token cached=${tokenDiagnostics.cachedPresent} secure=${tokenDiagnostics.securePresent} fallback=${tokenDiagnostics.fallbackPresent} resolved=${tokenDiagnostics.resolvedPresent} masked=${tokenDiagnostics.maskedResolved}',
      if (tokenDiagnostics.error.isNotEmpty)
        '$prefix token error=${tokenDiagnostics.error}',
    ];
  }
}
