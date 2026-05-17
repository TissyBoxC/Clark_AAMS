import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthTokenStore {
  AuthTokenStore._();

  static final AuthTokenStore instance = AuthTokenStore._();

  static const _loginCodeKey = 'clark_login_code';
  static const _secureStorage = FlutterSecureStorage();
  String _cachedLoginCode = '';

  Future<String> readLoginCode() async {
    if (_cachedLoginCode.isNotEmpty) {
      return _cachedLoginCode;
    }
    try {
      final value = await _secureStorage.read(key: _loginCodeKey);
      if (value != null && value.trim().isNotEmpty) {
        _cachedLoginCode = value.trim();
        return _cachedLoginCode;
      }
    } catch (_) {
      // Fall back to SharedPreferences when secure storage is unavailable.
    }
    final prefs = await SharedPreferences.getInstance();
    _cachedLoginCode = prefs.getString(_loginCodeKey)?.trim() ?? '';
    return _cachedLoginCode;
  }

  Future<void> saveLoginCode(String loginCode) async {
    final normalized = loginCode.trim();
    if (normalized.isEmpty) {
      return;
    }
    _cachedLoginCode = normalized;
    try {
      await _secureStorage.write(key: _loginCodeKey, value: normalized);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_loginCodeKey);
      return;
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_loginCodeKey, normalized);
    }
  }

  Future<void> clearLoginCode() async {
    _cachedLoginCode = '';
    try {
      await _secureStorage.delete(key: _loginCodeKey);
    } catch (_) {
      // Ignore and clear the fallback store below.
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loginCodeKey);
  }

  Future<Map<String, String>> authHeaders({
    bool contentTypeJson = false,
  }) async {
    final headers = <String, String>{};
    if (contentTypeJson) {
      headers['Content-Type'] = 'application/json';
    }
    final loginCode = await readLoginCode();
    if (loginCode.isNotEmpty) {
      headers['X-Clark-Aams-Login-Code'] = loginCode;
    }
    return headers;
  }

  Future<AuthTokenDiagnostics> diagnostics() async {
    String secureValue = '';
    String fallbackValue = '';
    String error = '';
    try {
      secureValue = (await _secureStorage.read(key: _loginCodeKey)) ?? '';
    } catch (exception) {
      error = exception.toString();
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      fallbackValue = prefs.getString(_loginCodeKey) ?? '';
    } catch (exception) {
      error = error.isEmpty ? exception.toString() : '$error | $exception';
    }
    return AuthTokenDiagnostics(
      cachedPresent: _cachedLoginCode.isNotEmpty,
      securePresent: secureValue.trim().isNotEmpty,
      fallbackPresent: fallbackValue.trim().isNotEmpty,
      resolvedPresent: (await readLoginCode()).isNotEmpty,
      maskedResolved: _mask(await readLoginCode()),
      error: error,
    );
  }

  String _mask(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return 'empty';
    }
    if (normalized.length <= 6) {
      return '***';
    }
    return '${normalized.substring(0, 3)}***${normalized.substring(normalized.length - 3)}';
  }
}

class AuthTokenDiagnostics {
  const AuthTokenDiagnostics({
    required this.cachedPresent,
    required this.securePresent,
    required this.fallbackPresent,
    required this.resolvedPresent,
    required this.maskedResolved,
    required this.error,
  });

  final bool cachedPresent;
  final bool securePresent;
  final bool fallbackPresent;
  final bool resolvedPresent;
  final String maskedResolved;
  final String error;
}
