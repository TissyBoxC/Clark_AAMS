import 'package:clark_aams/models/error_codes.dart';
import 'package:clark_aams/services/clark_backend_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('classifyError 按业务码', () {
    test('配额用尽与限流是两种不同语义', () {
      // 都是 HTTP 429，但一个明天才能用、一个稍等即可
      expect(classifyError(ErrorCodes.quotaExceeded), ErrorKind.quota);
      expect(classifyError(ErrorCodes.rateLimited), ErrorKind.rateLimit);
    });

    test('配额用尽不可重试，限流可重试', () {
      expect(isRetryable(ErrorKind.quota), isFalse);
      expect(isRetryable(ErrorKind.rateLimit), isTrue);
      expect(isRetryable(ErrorKind.server), isTrue);
      expect(isRetryable(ErrorKind.auth), isFalse);
      expect(isRetryable(ErrorKind.input), isFalse);
    });

    test('鉴权与权限分开', () {
      expect(classifyError(ErrorCodes.loginInvalid), ErrorKind.auth);
      expect(classifyError(ErrorCodes.forbidden), ErrorKind.forbidden);
    });

    test('输入类错误', () {
      expect(classifyError(ErrorCodes.badRequest), ErrorKind.input);
      expect(classifyError(ErrorCodes.userEmailConflict), ErrorKind.input);
      expect(classifyError(ErrorCodes.schoolNotFound), ErrorKind.input);
      expect(classifyError(ErrorCodes.importerNotFound), ErrorKind.input);
      expect(classifyError(ErrorCodes.userNotFound), ErrorKind.input);
    });

    test('5xxxx 归为服务端错误', () {
      expect(classifyError(ErrorCodes.internalError), ErrorKind.server);
      expect(classifyError(ErrorCodes.aiRequestFailed), ErrorKind.server);
      expect(classifyError(ErrorCodes.courseParseFailed), ErrorKind.server);
    });

    test('未知业务码不误判为输入错误', () {
      // 后端未来新增的 41xxx，不应被当成用户填错
      expect(classifyError(41001), ErrorKind.unknown);
    });
  });

  group('classifyError 按 HTTP 状态码回退', () {
    test('无业务码时用状态码判定', () {
      expect(classifyError(null, status: 401), ErrorKind.auth);
      expect(classifyError(null, status: 403), ErrorKind.forbidden);
      expect(classifyError(null, status: 429), ErrorKind.rateLimit);
      expect(classifyError(null, status: 500), ErrorKind.server);
      expect(classifyError(null, status: 400), ErrorKind.input);
    });

    test('完全没有信息时为 unknown', () {
      expect(classifyError(null), ErrorKind.unknown);
    });

    test('业务码优先于状态码', () {
      // HTTP 429 + 业务码 42901 → 配额用尽（而不是笼统的限流）
      expect(classifyError(ErrorCodes.quotaExceeded, status: 429), ErrorKind.quota);
    });
  });

  group('ApiException', () {
    test('从业务码得出分类', () {
      const exception = ApiException(ErrorCodes.quotaExceeded, '今日额度已用完');
      expect(exception.kind, ErrorKind.quota);
      expect(exception.retryable, isFalse);
    });

    test('无业务码时从状态码得出分类', () {
      const exception = ApiException(429, 'HTTP 429', status: 429);
      expect(exception.kind, ErrorKind.rateLimit);
      expect(exception.retryable, isTrue);
    });

    test('未登录错误可被识别', () {
      const exception = ApiException(ErrorCodes.loginInvalid, '请先登录');
      expect(exception.kind, ErrorKind.auth);
    });
  });
}
