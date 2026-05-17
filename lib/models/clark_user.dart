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

  bool get isAuthenticated => id > 0;

  String get displayName {
    if (username.trim().isNotEmpty) {
      return username.trim();
    }
    if (email.trim().isNotEmpty) {
      return email.trim();
    }
    return '未登录';
  }

  String get maskedLoginCode {
    final value = loginCode.trim();
    if (value.length <= 6) {
      return value.isEmpty ? '未生成' : '******';
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
