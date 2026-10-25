/// 账号角色，与后端 `security/Role` 一一对应。
///
/// 背景（审查文档 P1）：此前 App 只有「登录 / 未登录」两态，
/// 没有角色概念，因此无法表达「管理员进入后台、普通用户进入课表」
/// 这类分流。后端已提供 `GET /api/v1/auth/me` 统一回答身份，
/// App 这里用同一套枚举承接。
enum UserRole {
  guest('guest'),
  user('user'),
  admin('admin');

  const UserRole(this.wire);

  /// 传输值，与后端一致（后端枚举名大写，`wire()` 返回小写）。
  final String wire;

  bool get isAdmin => this == UserRole.admin;

  bool get isAuthenticated => this != UserRole.guest;

  /// 解析后端返回的角色值；**未知值一律视为 guest**（失败即最小权限）。
  static UserRole fromWire(Object? value) {
    if (value is! String) {
      return UserRole.guest;
    }
    final normalized = value.trim().toLowerCase();
    for (final role in UserRole.values) {
      if (role.wire == normalized) {
        return role;
      }
    }
    return UserRole.guest;
  }
}
