import '../resources/app_strings.dart';

class ClarkUser {
  const ClarkUser({
    required this.id,
    required this.username,
    required this.email,
    required this.loginCode,
    required this.emailBound,
    required this.emailVerified,
    required this.questionAnalysisCount,
  });

  static const empty = ClarkUser(
    id: 0,
    username: '',
    email: '',
    loginCode: '',
    emailBound: false,
    emailVerified: false,
    questionAnalysisCount: 0,
  );

  final int id;
  final String username;
  final String email;
  final String loginCode;
  final bool emailBound;
  final bool emailVerified;
  final int questionAnalysisCount;

  /*
   * id > 0 表示身份已由后端确认；loginCode 非空表示这台设备持有凭据。
   * 两者满足其一就算已登录。
   *
   * 为什么要看登录码：启动时若网络不通，身份核对拿不到 id，
   * 但用户明明登录过，本地也存着凭据。只看 id 会把人踢回登录页，
   * 表现就是「关掉应用再打开就掉登录」，可再手动登录一次又能进。
   */
  bool get isAuthenticated => id > 0 || loginCode.trim().isNotEmpty;

  String get displayName {
    if (username.trim().isNotEmpty) {
      return username.trim();
    }
    if (email.trim().isNotEmpty) {
      return email.trim();
    }
    return AppStrings.notLoggedIn;
  }

  String get maskedLoginCode {
    final value = loginCode.trim();
    if (value.length <= 6) {
      return value.isEmpty ? AppStrings.notGenerated : '******';
    }
    return '${value.substring(0, 3)}******${value.substring(value.length - 3)}';
  }

  factory ClarkUser.fromJson(Map<String, Object?> json) {
    return ClarkUser(
      id: _asInt(json['id']) ?? 0,
      username: (json['username'] as String? ?? '').trim(),
      email: (json['email'] as String? ?? '').trim(),
      loginCode: (json['loginCode'] as String? ?? '').trim(),
      emailBound: json['emailBound'] == true,
      emailVerified: json['emailVerified'] == true,
      questionAnalysisCount: _asInt(json['questionAnalysisCount']) ?? 0,
    );
  }

  static int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }
}
