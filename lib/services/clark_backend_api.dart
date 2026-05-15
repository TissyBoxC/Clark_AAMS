import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/backend_config.dart';
import '../models/app_version.dart';
import '../models/course.dart';
import '../models/school.dart';

class ClarkBackendApi {
  ClarkBackendApi({http.Client? client}) : _client = client ?? http.Client();

  static final ClarkBackendApi instance = ClarkBackendApi();

  final http.Client _client;

  static const _timeout = Duration(seconds: 20);

  Future<List<School>> getSchools() async {
    final data = await _get('/api/v1/schools');
    if (data is! List) {
      throw const ApiException(50003, '学校列表响应格式错误');
    }
    return [
      for (final item in data)
        if (item is Map<String, Object?>)
          School.fromJson(item)
        else if (item is Map)
          School.fromJson(item.cast<String, Object?>()),
    ];
  }

  Future<School> getSchool(String schoolId) async {
    final data = await _get('/api/v1/schools/$schoolId');
    if (data is Map<String, Object?>) {
      return School.fromJson(data);
    }
    if (data is Map) {
      return School.fromJson(data.cast<String, Object?>());
    }
    throw const ApiException(50003, '学校配置响应格式错误');
  }

  Future<List<Course>> importCourses({
    required String schoolId,
    required String cookie,
    required String studentId,
    required String successUrl,
  }) async {
    final data = await _post('/api/v1/imports/$schoolId/courses', {
      'loginSession': {
        'cookie': cookie,
        'studentId': studentId,
        'successUrl': successUrl,
        'extra': <String, Object?>{},
      },
      'options': {'term': '', 'preferCurrentTerm': true},
    });
    if (data is! Map) {
      throw const ApiException(50003, '课表导入响应格式错误');
    }
    final coursesJson = data['courses'];
    if (coursesJson is! List) {
      throw const ApiException(50003, '课表数据响应格式错误');
    }
    return [
      for (var index = 0; index < coursesJson.length; index++)
        if (coursesJson[index] is Map<String, Object?>)
          Course.fromJson(
            coursesJson[index] as Map<String, Object?>,
            fallbackId: index + 1,
          )
        else if (coursesJson[index] is Map)
          Course.fromJson(
            (coursesJson[index] as Map).cast<String, Object?>(),
            fallbackId: index + 1,
          ),
    ];
  }

  Future<AppVersionInfo> checkVersion({
    required String platform,
    required String currentVersion,
    required int? currentBuild,
    required String channel,
  }) async {
    final data = await _post('/api/v1/app/version/check', {
      'platform': platform,
      'currentVersion': currentVersion,
      'currentBuild': currentBuild,
      'channel': channel,
      'extra': <String, Object?>{},
    });
    if (data is Map<String, Object?>) {
      return AppVersionInfo.fromJson(data);
    }
    if (data is Map) {
      return AppVersionInfo.fromJson(data.cast<String, Object?>());
    }
    throw const ApiException(50003, '版本检查响应格式错误');
  }

  Future<Object?> _get(String path) async {
    final response = await _client
        .get(BackendConfig.uri(path))
        .timeout(_timeout);
    return _unwrap(response);
  }

  Future<Object?> _post(String path, Map<String, Object?> body) async {
    final response = await _client
        .post(
          BackendConfig.uri(path),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(_timeout);
    return _unwrap(response);
  }

  Object? _unwrap(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        response.statusCode,
        '后端请求失败：HTTP ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map) {
      throw const ApiException(50003, '后端响应格式错误');
    }

    final code = _asInt(decoded['code']) ?? 50003;
    final message = decoded['message'] as String? ?? '后端请求失败';
    if (code != 0) {
      throw ApiException(code, message);
    }
    return decoded['data'];
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

class ApiException implements Exception {
  const ApiException(this.code, this.message);

  final int code;
  final String message;

  @override
  String toString() => message;
}
