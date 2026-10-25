/// 统一错误码与错误分类（P2-3）。
///
/// 后端 `ErrorCode` 的镜像。三端共享同一套数字，避免出现
/// 「后端返回 42901、App 只认状态码」这类静默不一致。
///
/// 数字分段约定：
/// - `0`      成功
/// - `40xxx`  客户端错误（参数、登录、权限、资源不存在、冲突）
/// - `429xx`  限流与配额
/// - `50xxx`  服务端错误
library;

/// 后端错误码。
class ErrorCodes {
  ErrorCodes._();

  static const int ok = 0;

  static const int badRequest = 40001;
  static const int loginInvalid = 40101;
  static const int forbidden = 40301;

  static const int schoolNotFound = 40401;
  static const int importerNotFound = 40402;
  static const int userNotFound = 40403;

  static const int userEmailConflict = 40901;

  /// 当日配额用尽，需等到重置（明天）。**不可重试**。
  static const int quotaExceeded = 42901;

  /// 短时限流，稍后可重试。
  static const int rateLimited = 42902;

  static const int academicRequestFailed = 50001;
  static const int courseParseFailed = 50002;
  static const int internalError = 50003;
  static const int aiRequestFailed = 50004;
}

/// 错误分类，决定 UI 该怎么反应。
enum ErrorKind {
  /// 需要重新登录。
  auth,

  /// 身份不够（提示无权限，不跳登录）。
  forbidden,

  /// 配额用尽（提示明天再试，不提供重试）。
  quota,

  /// 太频繁（提示稍后再试，可重试）。
  rateLimit,

  /// 用户输入有问题（就地提示）。
  input,

  /// 服务端故障。
  server,

  /// 未识别。
  unknown,
}

/// 把错误码归入分类。
///
/// 优先看业务码；未知业务码再退回 HTTP 状态码判断，
/// 这样后端新增错误码时 App 不会立刻显示成「未知错误」。
ErrorKind classifyError(int? code, {int? status}) {
  if (code == ErrorCodes.quotaExceeded) {
    return ErrorKind.quota;
  }
  if (code == ErrorCodes.rateLimited) {
    return ErrorKind.rateLimit;
  }
  if (code == ErrorCodes.loginInvalid) {
    return ErrorKind.auth;
  }
  if (code == ErrorCodes.forbidden) {
    return ErrorKind.forbidden;
  }
  if (code == ErrorCodes.badRequest ||
      code == ErrorCodes.userEmailConflict ||
      code == ErrorCodes.schoolNotFound ||
      code == ErrorCodes.importerNotFound ||
      code == ErrorCodes.userNotFound) {
    return ErrorKind.input;
  }
  if (code != null && code >= 50000) {
    return ErrorKind.server;
  }

  if (status == 401) {
    return ErrorKind.auth;
  }
  if (status == 403) {
    return ErrorKind.forbidden;
  }
  if (status == 429) {
    return ErrorKind.rateLimit;
  }
  if (status != null && status >= 500) {
    return ErrorKind.server;
  }
  if (status != null && status >= 400) {
    return ErrorKind.input;
  }
  return ErrorKind.unknown;
}

/// 该分类是否值得让用户原地重试（配额用尽重试也没用）。
bool isRetryable(ErrorKind kind) {
  return kind == ErrorKind.rateLimit || kind == ErrorKind.server;
}
