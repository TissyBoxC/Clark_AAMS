import 'package:clark_aams/models/user_role.dart';
import 'package:clark_aams/services/clark_backend_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserRole', () {
    test('从后端传输值解析', () {
      expect(UserRole.fromWire('admin'), UserRole.admin);
      expect(UserRole.fromWire('user'), UserRole.user);
      expect(UserRole.fromWire('guest'), UserRole.guest);
    });

    test('大小写与空白不影响解析', () {
      expect(UserRole.fromWire(' ADMIN '), UserRole.admin);
      expect(UserRole.fromWire('User'), UserRole.user);
    });

    test('未知值一律降级为 guest（最小权限）', () {
      expect(UserRole.fromWire('root'), UserRole.guest);
      expect(UserRole.fromWire('superadmin'), UserRole.guest);
      expect(UserRole.fromWire(''), UserRole.guest);
    });

    test('非字符串输入降级为 guest', () {
      expect(UserRole.fromWire(null), UserRole.guest);
      expect(UserRole.fromWire(1), UserRole.guest);
      expect(UserRole.fromWire(<String, Object?>{}), UserRole.guest);
    });

    test('权限谓词', () {
      expect(UserRole.admin.isAdmin, isTrue);
      expect(UserRole.user.isAdmin, isFalse);
      expect(UserRole.guest.isAdmin, isFalse);

      expect(UserRole.admin.isAuthenticated, isTrue);
      expect(UserRole.user.isAuthenticated, isTrue);
      expect(UserRole.guest.isAuthenticated, isFalse);
    });

    test('wire 值与后端一致', () {
      expect(UserRole.guest.wire, 'guest');
      expect(UserRole.user.wire, 'user');
      expect(UserRole.admin.wire, 'admin');
    });
  });

  group('AuthIdentity', () {
    test('guest 快照未登录', () {
      expect(AuthIdentity.guest.isAuthenticated, isFalse);
      expect(AuthIdentity.guest.isAdmin, isFalse);
      expect(AuthIdentity.guest.user, isNull);
    });

    test('authenticated 为 false 时即使角色是 admin 也不算登录', () {
      const identity = AuthIdentity(
        role: UserRole.admin,
        authenticated: false,
        displayName: 'admin',
      );
      expect(identity.isAuthenticated, isFalse);
    });

    test('管理员身份就绪', () {
      const identity = AuthIdentity(
        role: UserRole.admin,
        authenticated: true,
        displayName: 'admin',
      );
      expect(identity.isAuthenticated, isTrue);
      expect(identity.isAdmin, isTrue);
    });
  });
}
