import 'package:flutter/foundation.dart';

import '../models/clark_user.dart';
import '../models/user_role.dart';
import '../widget/widget_service.dart';
import 'auth_token_store.dart';
import 'clark_backend_api.dart';

class AuthSession extends ChangeNotifier {
  AuthSession._();

  static final AuthSession instance = AuthSession._();

  ClarkUser _user = ClarkUser.empty;
  UserRole _role = UserRole.guest;
  bool _initialized = false;
  bool _busy = false;

  ClarkUser get user => _user;

  /// 当前角色（审查条目 P1-6）。
  ///
  /// 只由后端 `GET /api/v1/auth/me` 决定，App 不自行推断，
  /// 避免与后端判据漂移。
  UserRole get role => _role;
  bool get isAdmin => _role.isAdmin;
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
        _role = UserRole.guest;
      } else {
        await _loadIdentity();
      }
    } catch (_) {
      _user = ClarkUser.empty;
      _role = UserRole.guest;
    } finally {
      _initialized = true;
      _setBusy(false);
    }
  }

  /// 通过统一身份接口刷新用户与角色。
  ///
  /// 后端自 P0-4 起在 `/user/me` 不回传登录码，
  /// 因此只有在返回了非空码时才覆盖本地缓存；
  /// 空值覆盖会把用户每次刷新都登出。
  Future<void> _loadIdentity() async {
    final identity = await ClarkBackendApi.instance.fetchIdentity();
    _role = identity.role;

    final user = identity.user;
    if (user != null && user.isAuthenticated) {
      // 身份接口的 user 不含登录码，保留本地已有的那一份
      final storedCode = await AuthTokenStore.instance.readLoginCode();
      _user = ClarkUser(
        id: user.id,
        username: user.username,
        email: user.email,
        loginCode: user.loginCode.isNotEmpty ? user.loginCode : storedCode,
        emailBound: user.emailBound,
        emailVerified: user.emailVerified,
        questionAnalysisCount: user.questionAnalysisCount,
      );
    } else {
      _user = ClarkUser.empty;
    }

    if (!identity.isAuthenticated) {
      _role = UserRole.guest;
    }
  }

  Future<void> refresh() async {
    _setBusy(true);
    try {
      final loginCode = await AuthTokenStore.instance.readLoginCode();
      if (loginCode.isEmpty) {
        _user = ClarkUser.empty;
        _role = UserRole.guest;
        return;
      }
      await _loadIdentity();
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
      _role = UserRole.guest;
      _setBusy(false);
      await WidgetService.updateWidget();
    }
  }

  /// 退出所有设备：吊销旧登录码，换取新码并写入本地。
  ///
  /// 进入这个状态后，其它设备上保存的旧登录码立即失效。
  Future<void> logoutAllDevices() async {
    _setBusy(true);
    try {
      final rotated = await ClarkBackendApi.instance.rotateLoginCode();
      await _acceptUser(rotated);
    } finally {
      _setBusy(false);
    }
  }

  Future<void> _acceptUser(ClarkUser user) async {
    _user = user;
    // 登录成功即具备普通用户身份；管理员身份需由 `/auth/me` 确认，
    // 这里不臆测，避免把用户登录码误当后台权限。
    _role = user.isAuthenticated ? UserRole.user : UserRole.guest;
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
