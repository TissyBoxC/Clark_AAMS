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
import '../utils/json_util.dart';
import '../models/error_codes.dart';
import '../models/school.dart';
import '../models/school_lesson_times.dart';
import '../models/user_role.dart';
import '../resources/app_strings.dart';
import 'auth_token_store.dart';

/// 统一身份快照（`GET /api/v1/auth/me`）。
class AuthIdentity {
  const AuthIdentity({
    required this.role,
    required this.authenticated,
    required this.displayName,
    this.user,
  });

  /// 未登录。
  static const guest = AuthIdentity(
    role: UserRole.guest,
    authenticated: false,
    displayName: '',
  );

  final UserRole role;
  final bool authenticated;

  /// 展示名：管理员为后台账号名，用户为用户名/邮箱。
  final String displayName;

  /// 用户资料；管理员或未登录时为 null。
  final ClarkUser? user;

  bool get isAdmin => role.isAdmin;
  bool get isAuthenticated => authenticated && role.isAuthenticated;
}

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
    return [for (final item in JsonUtil.asMapList(data)) School.fromJson(item)];
  }

  Future<School> getSchool(String schoolId) async {
    final data = await _get('/api/v1/schools/$schoolId');
    final map = JsonUtil.asMap(data);
    if (map != null) {
      return School.fromJson(map);
    }
    throw const ApiException(50003, AppStrings.invalidSchoolConfigResponse);
  }

  Future<SchoolLessonTimes> getSchoolLessonTimes(String schoolId) async {
    final data = await _get('/api/v1/schools/$schoolId/lesson-times');
    final map = JsonUtil.asMap(data);
    if (map != null) {
      return SchoolLessonTimes.fromJson(map);
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
      for (final item in JsonUtil.asMapList(data))
        SchoolLessonTimes.fromJson(item),
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

  /// 直接传页面 HTML 给后端解析。
  ///
  /// 这是唯一正确的做法：App 端只负责把页面内容原样交出去，
  /// 解析规则全部留在后端。理由很实在——后端那套解析器有真实页面样本
  /// 和 180 多项测试撑着，而 App 里用 JS 现场判断表格是课表还是表头，
  /// 根本判不准（实测把"星期一/星期二"当成了 7 门课）。
  ///
  /// [frames] 用来带上内嵌页的内容：课表常在不带 src 属性的 iframe 里，
  /// 只传外层 HTML 会拿不到表格。
  Future<List<Course>> importCoursesFromHtml({
    required String school,
    required String schoolName,
    required String html,
    List<Map<String, String?>> frames = const [],
  }) async {
    final data = await _post('/api/v1/imports/courses/html', {
      'school': school,
      'schoolName': schoolName,
      'html': html,
      'frames': frames,
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

    // P2-2：后端已统一为 {code,message,data} 信封，data 为课程数组。
    final data = _unwrap(response);
    if (data is! List) {
      throw const ApiException(
        50003,
        AppStrings.invalidPickupCourseDataResponse,
      );
    }
    return _parseCourseList(data);
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
    final map = JsonUtil.asMap(data);
    if (map != null) {
      return AppVersionInfo.fromJson(map);
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
    final map = JsonUtil.asMap(data);
    if (map != null) {
      return map;
    }
    throw const ApiException(50003, AppStrings.invalidQuestionAnalysisResponse);
  }

  Future<Map<String, Object?>> analyzeFillBlankQuestion({
    required String questionType,
    required String questionContent,
    String? material,
    String? referenceAnswer,
    String? studentAnswer,
  }) async {
    final data = await _post('/api/v1/questions/analyze/fill-blank', {
      'question_type': questionType,
      'question_content': questionContent,
      if (material != null && material.trim().isNotEmpty)
        'material': material.trim(),
      if (referenceAnswer != null && referenceAnswer.trim().isNotEmpty)
        'reference_answer': referenceAnswer.trim(),
      if (studentAnswer != null && studentAnswer.trim().isNotEmpty)
        'student_answer': studentAnswer.trim(),
    }, timeout: _questionAnalyzeTimeout);
    final map = JsonUtil.asMap(data);
    if (map != null) {
      return map;
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

  /// 查询统一身份（角色 + 资料）。
  ///
  /// 后端用一个接口回答「我是谁、什么角色」，
  /// App 不再需要分别推断用户态与管理态。
  Future<AuthIdentity> fetchIdentity() async {
    final data = await _get('/api/v1/auth/me');
    if (data is! Map) {
      return AuthIdentity.guest;
    }
    final rawUser = data['user'];
    return AuthIdentity(
      role: UserRole.fromWire(data['role']),
      authenticated: data['authenticated'] == true,
      displayName: (data['displayName'] as String? ?? '').trim(),
      user: JsonUtil.asMap(rawUser) != null
          ? ClarkUser.fromJson(JsonUtil.asMap(rawUser)!)
          : null,
    );
  }

  /// 退出所有设备：吊销旧登录码并换取新的。
  ///
  /// 返回的新登录码由调用方立即写入 [AuthTokenStore]，
  /// 旧码从此失效（其它设备的会话下次请求即被拒）。
  Future<ClarkUser> rotateLoginCode() async {
    final data = await _post('/api/v1/user/login-code/rotate', {});
    return _parseUser(data);
  }

  Future<void> logout() async {
    await _post('/api/v1/user/logout', {});
  }

  /// 拉取服务端保存的「我的课表」（P3-1）。
  ///
  /// 服务端返回的字段与 [Course.fromJson] 已对齐（含 weekRanges/weekRule），
  /// 因此直接复用同一个解析入口，不需要第二套映射。
  Future<List<Course>> fetchMyCourses() async {
    final data = await _get('/api/v1/courses/schedule');
    if (data is! List) {
      throw const ApiException(50003, AppStrings.invalidBackendResponse);
    }
    final items = JsonUtil.asMapList(data);
    return [
      for (var i = 0; i < items.length; i++)
        Course.fromJson(items[i], fallbackId: i + 1),
    ];
  }

  /// 用一组课程整体覆盖服务端课表。
  Future<List<Course>> replaceMyCourses(List<Course> courses) async {
    final data = await _send(
      'PUT',
      '/api/v1/courses/schedule',
      body: [for (final course in courses) _coursePayload(course)],
    );
    if (data is! List) {
      throw const ApiException(50003, AppStrings.invalidBackendResponse);
    }
    final items = JsonUtil.asMapList(data);
    return [
      for (var i = 0; i < items.length; i++)
        Course.fromJson(items[i], fallbackId: i + 1),
    ];
  }

  /// 删除服务端的一门课。
  Future<void> deleteMyCourse(int courseId) async {
    await _send('DELETE', '/api/v1/courses/schedule/$courseId');
  }

  /// 清空服务端课表，返回删除条数。
  Future<int> clearMyCourses() async {
    final data = await _send('DELETE', '/api/v1/courses/schedule');
    final map = JsonUtil.asMap(data);
    if (map != null) {
      final removed = map['removed'];
      if (removed is int) {
        return removed;
      }
      if (removed is num) {
        return removed.toInt();
      }
    }
    return 0;
  }

  /// 写请求只提交真相源字段，派生字段交给服务端计算。
  Map<String, Object?> _coursePayload(Course course) {
    return {
      'name': course.name,
      'dayOfWeek': course.dayOfWeek,
      'startLesson': course.startLesson,
      'endLesson': course.endLesson,
      'location': course.location,
      'teacher': course.teacher,
      'rawTime': course.rawTime,
      'weekRanges': [
        for (final range in course.weekPattern.ranges) [range.start, range.end],
      ],
      'weekRule': course.weekPattern.rule.wire,
    };
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

  /// 通用请求：课表资源需要 PUT/DELETE，而 [http.Client] 没有统一入口。
  ///
  /// [body] 可以是 Map（单个对象）或 List（批量），为 null 时不带请求体。
  Future<Object?> _send(
    String method,
    String path, {
    Object? body,
    Duration timeout = _timeout,
  }) async {
    final headers = await AuthTokenStore.instance.authHeaders(
      contentTypeJson: body != null,
    );
    final request = http.Request(method, BackendConfig.uri(path))
      ..headers.addAll(headers);
    if (body != null) {
      request.body = jsonEncode(body);
    }
    final streamed = await _client.send(request).timeout(timeout);
    final response = await http.Response.fromStream(streamed);
    return _unwrap(response);
  }

  Object? _unwrap(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      // 优先用信封里的业务码（如 42901），拿不到才退回 HTTP 状态码，
      // 这样页面能区分「配额用尽」和「限流」这类语义不同的 429。
      final businessCode = _businessCodeOf(response);
      throw ApiException(
        businessCode ?? response.statusCode,
        _responseErrorMessage(
          response,
          AppStrings.backendRequestFailed(response.statusCode),
        ),
        status: response.statusCode,
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

  /// 从错误响应体里取信封业务码；没有就返回 null。
  int? _businessCodeOf(http.Response response) {
    final body = utf8.decode(response.bodyBytes).trim();
    if (body.isEmpty) {
      return null;
    }
    try {
      final decoded = JsonUtil.asMap(JsonUtil.tryDecode(body));
      if (decoded != null) {
        final code = _asInt(decoded['code']);
        if (code != null && code != 0) {
          return code;
        }
      }
    } catch (_) {
      // 非 JSON 响应（网关 HTML 等），退回 HTTP 状态码
    }
    return null;
  }

  String _responseErrorMessage(http.Response response, String fallback) {
    final body = utf8.decode(response.bodyBytes).trim();
    if (body.isEmpty) {
      return fallback;
    }
    try {
      final decoded = JsonUtil.asMap(JsonUtil.tryDecode(body));
      if (decoded != null) {
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
    final items = JsonUtil.asMapList(coursesJson);
    return [
      for (var index = 0; index < items.length; index++)
        Course.fromJson(items[index], fallbackId: index + 1),
    ];
  }

  ClarkUser _parseUser(Object? data) {
    final map = JsonUtil.asMap(data);
    if (map != null) {
      return ClarkUser.fromJson(map);
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
  const ApiException(this.code, this.message, {this.status});

  /// 后端业务码（见 [ErrorCodes]）；网络层错误时可能为 HTTP 状态码。
  final int code;

  final String message;

  /// HTTP 状态码，部分错误（如未带信封的网关错误）才有。
  final int? status;

  /// 错误分类（P2-3），页面据此决定跳登录 / 提示无权限 / 提示明天再试。
  ErrorKind get kind {
    // 业务码与 HTTP 状态码可能混用（_unwrap 在无信封时用状态码当 code），
    // 这里两个都交给分类器，由它按分段规则裁决。
    final fromCode = classifyError(code, status: status);
    if (fromCode != ErrorKind.unknown) {
      return fromCode;
    }
    return classifyError(null, status: status ?? code);
  }

  /// 该错误是否值得让用户原地重试（配额用尽重试无意义）。
  bool get retryable => isRetryable(kind);

  @override
  String toString() => message;
}
