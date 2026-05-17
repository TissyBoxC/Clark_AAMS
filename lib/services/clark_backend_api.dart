import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

import '../config/backend_config.dart';
import '../models/app_version.dart';
import '../models/clark_user.dart';
import '../models/course.dart';
import '../models/school.dart';
import '../models/school_lesson_times.dart';
import '../resources/app_strings.dart';
import 'auth_token_store.dart';

class ClarkBackendApi {
  ClarkBackendApi({http.Client? client}) : _client = client ?? http.Client();

  static final ClarkBackendApi instance = ClarkBackendApi();

  final http.Client _client;

  static const _timeout = Duration(seconds: 20);
  static const _questionAnalyzeTimeout = Duration(minutes: 5);
  static const _ocrTimeout = Duration(seconds: 180);

  Future<List<School>> getSchools() async {
    final data = await _get('/api/v1/schools');
    if (data is! List) {
      throw const ApiException(50003, AppStrings.invalidSchoolsResponse);
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
    throw const ApiException(50003, AppStrings.invalidSchoolConfigResponse);
  }

  Future<SchoolLessonTimes> getSchoolLessonTimes(String schoolId) async {
    final data = await _get('/api/v1/schools/$schoolId/lesson-times');
    if (data is Map<String, Object?>) {
      return SchoolLessonTimes.fromJson(data);
    }
    if (data is Map) {
      return SchoolLessonTimes.fromJson(data.cast<String, Object?>());
    }
    throw const ApiException(
      50003,
      AppStrings.invalidSchoolLessonTimesResponse,
    );
  }

  Future<List<SchoolLessonTimes>> getGeneralLessonTimeProfiles() async {
    final data = await _get('/api/v1/schools/lesson-time-profiles');
    if (data is! List) {
      throw const ApiException(
        50003,
        AppStrings.invalidGeneralLessonTimesResponse,
      );
    }
    return [
      for (final item in data)
        if (item is Map<String, Object?>)
          SchoolLessonTimes.fromJson(item)
        else if (item is Map)
          SchoolLessonTimes.fromJson(item.cast<String, Object?>()),
    ];
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
      throw const ApiException(50003, AppStrings.invalidCourseImportResponse);
    }
    final coursesJson = data['courses'];
    if (coursesJson is! List) {
      throw const ApiException(50003, AppStrings.invalidCourseDataResponse);
    }
    return _parseCourseList(coursesJson);
  }

  Future<CoursePickupResult> recognizeCourseImages(List<File> images) async {
    if (images.isEmpty) {
      throw const ApiException(40001, AppStrings.selectCourseImageFirst);
    }

    final request = http.MultipartRequest(
      'POST',
      BackendConfig.uri('/api/v1/course-pickups'),
    );
    request.headers.addAll(
      await AuthTokenStore.instance.authHeaders(contentTypeJson: false),
    );
    for (final image in images) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'images',
          image.path,
          contentType: _imageContentType(image.path),
        ),
      );
    }

    final streamed = await _client.send(request).timeout(_ocrTimeout);
    final response = await http.Response.fromStream(streamed);
    final data = _unwrap(response);
    if (data is! Map) {
      throw const ApiException(50003, AppStrings.invalidOcrResponse);
    }

    final pickupCode = data['pickupCode'] as String? ?? '';
    final coursesJson = data['courses'];
    if (pickupCode.isEmpty || coursesJson is! List) {
      throw const ApiException(50003, AppStrings.invalidOcrCourseDataResponse);
    }

    return CoursePickupResult(
      pickupCode: pickupCode,
      courses: _parseCourseList(coursesJson),
    );
  }

  Future<List<Course>> getCoursesByPickupCode(String code) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.length != 8) {
      throw const ApiException(40001, AppStrings.enterEightDigitPickupCode);
    }

    final response = await _client
        .get(
          BackendConfig.uri('/api/v1/course-pickups/$normalized'),
          headers: await AuthTokenStore.instance.authHeaders(),
        )
        .timeout(_timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        response.statusCode,
        _responseErrorMessage(
          response,
          AppStrings.pickupCodeFetchFailed(response.statusCode),
        ),
      );
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! List) {
      throw const ApiException(
        50003,
        AppStrings.invalidPickupCourseDataResponse,
      );
    }
    return _parseCourseList(decoded);
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
    throw const ApiException(50003, AppStrings.invalidVersionCheckResponse);
  }

  Future<Map<String, Object?>> analyzeQuestion({
    required String questionType,
    required String questionContent,
    required List<String> options,
  }) async {
    final data = await _post('/api/v1/questions/analyze', {
      'question_type': questionType,
      'question_content': questionContent,
      'options': options,
    }, timeout: _questionAnalyzeTimeout);
    if (data is Map<String, Object?>) {
      return data;
    }
    if (data is Map) {
      return data.cast<String, Object?>();
    }
    throw const ApiException(50003, AppStrings.invalidQuestionAnalysisResponse);
  }

  Future<ClarkUser> register({
    required String username,
    required String password,
    required String qqEmail,
  }) async {
    final data = await _post('/api/v1/user/register', {
      'username': username,
      'password': password,
      'qqEmail': qqEmail,
    });
    return _parseUser(data);
  }

  Future<ClarkUser> loginByEmail({
    required String qqEmail,
    required String password,
  }) async {
    final data = await _post('/api/v1/user/login', {
      'qqEmail': qqEmail,
      'password': password,
    });
    return _parseUser(data);
  }

  Future<ClarkUser> loginByCode(String loginCode) async {
    final data = await _post('/api/v1/user/login', {'loginCode': loginCode});
    return _parseUser(data);
  }

  Future<ClarkUser> currentUser() async {
    final data = await _get('/api/v1/user/me');
    return _parseUser(data);
  }

  Future<void> logout() async {
    await _post('/api/v1/user/logout', {});
  }

  Future<Object?> _get(String path) async {
    final response = await _client
        .get(
          BackendConfig.uri(path),
          headers: await AuthTokenStore.instance.authHeaders(),
        )
        .timeout(_timeout);
    return _unwrap(response);
  }

  Future<Object?> _post(
    String path,
    Map<String, Object?> body, {
    Duration timeout = _timeout,
  }) async {
    final response = await _client
        .post(
          BackendConfig.uri(path),
          headers: await AuthTokenStore.instance.authHeaders(
            contentTypeJson: true,
          ),
          body: jsonEncode(body),
        )
        .timeout(timeout);
    return _unwrap(response);
  }

  Object? _unwrap(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        response.statusCode,
        _responseErrorMessage(
          response,
          AppStrings.backendRequestFailed(response.statusCode),
        ),
      );
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map) {
      throw const ApiException(50003, AppStrings.invalidBackendResponse);
    }

    final code = _asInt(decoded['code']) ?? 50003;
    final message =
        decoded['message'] as String? ??
        AppStrings.backendRequestFailedFallback;
    if (code != 0) {
      throw ApiException(code, message);
    }
    return decoded['data'];
  }

  String _responseErrorMessage(http.Response response, String fallback) {
    final body = utf8.decode(response.bodyBytes).trim();
    if (body.isEmpty) {
      return fallback;
    }
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final message = decoded['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
    } catch (_) {
      // Fall through to a short raw response body below.
    }
    return body.length > 160 ? fallback : body;
  }

  MediaType _imageContentType(String path) {
    final mimeType =
        lookupMimeType(path, headerBytes: _fileHeaderBytes(path)) ??
        _mimeTypeFromExtension(path);
    return MediaType.parse(mimeType);
  }

  List<int>? _fileHeaderBytes(String path) {
    try {
      final file = File(path).openSync();
      try {
        final length = file.lengthSync();
        if (length <= 0) {
          return null;
        }
        return file.readSync(length < 32 ? length : 32);
      } finally {
        file.closeSync();
      }
    } catch (_) {
      return null;
    }
  }

  String _mimeTypeFromExtension(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    if (lower.endsWith('.gif')) {
      return 'image/gif';
    }
    if (lower.endsWith('.heic')) {
      return 'image/heic';
    }
    if (lower.endsWith('.heif')) {
      return 'image/heif';
    }
    return 'image/jpeg';
  }

  List<Course> _parseCourseList(List coursesJson) {
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

  ClarkUser _parseUser(Object? data) {
    if (data is Map<String, Object?>) {
      return ClarkUser.fromJson(data);
    }
    if (data is Map) {
      return ClarkUser.fromJson(data.cast<String, Object?>());
    }
    throw const ApiException(50003, AppStrings.invalidUserProfileResponse);
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

class CoursePickupResult {
  const CoursePickupResult({required this.pickupCode, required this.courses});

  final String pickupCode;
  final List<Course> courses;
}

class ApiException implements Exception {
  const ApiException(this.code, this.message);

  final int code;
  final String message;

  @override
  String toString() => message;
}
