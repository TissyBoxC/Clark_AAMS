class School {
  const School({
    required this.id,
    required this.name,
    required this.shortName,
    required this.supportsAcademicImport,
    required this.supportsImageRecognition,
    required this.login,
    required this.version,
    required this.lessonTimeProfile,
  });

  final String id;
  final String name;
  final String shortName;
  final bool supportsAcademicImport;
  final bool supportsImageRecognition;
  final SchoolLogin login;
  final int version;
  final String lessonTimeProfile;

  static School fromJson(Map<String, Object?> json) {
    final capabilities = _asMap(json['capabilities']);
    return School(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      shortName: json['shortName'] as String? ?? '',
      supportsAcademicImport: capabilities['academicImport'] as bool? ?? false,
      supportsImageRecognition:
          capabilities['imageRecognition'] as bool? ?? false,
      login: SchoolLogin.fromJson(_asMap(json['login'])),
      version: _asInt(json['version']) ?? 0,
      lessonTimeProfile: json['lessonTimeProfile'] as String? ?? '',
    );
  }

  static Map<String, Object?> _asMap(Object? value) {
    if (value is Map<String, Object?>) {
      return value;
    }
    if (value is Map) {
      return value.cast<String, Object?>();
    }
    return const <String, Object?>{};
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

class SchoolLogin {
  const SchoolLogin({
    required this.mode,
    required this.loginUrl,
    required this.successUrlPatterns,
  });

  final String mode;
  final String loginUrl;
  final List<String> successUrlPatterns;

  static SchoolLogin fromJson(Map<String, Object?> json) {
    final patterns = json['successUrlPatterns'];
    return SchoolLogin(
      mode: json['mode'] as String? ?? '',
      loginUrl: json['loginUrl'] as String? ?? '',
      successUrlPatterns: patterns is List
          ? patterns.whereType<String>().toList()
          : const <String>[],
    );
  }
}
