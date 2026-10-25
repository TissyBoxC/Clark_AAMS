import 'package:clark_aams/models/school.dart';
import 'package:clark_aams/screens/course_settings/course_settings_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

/// 课程设置页的三个纯判定/提示逻辑（P4-1）。
///
/// 它们原本是 `_CourseSettingsPageState` 的私有方法，混在 683 行的状态类里。
/// 抽出来的理由不是「行数好看」，而是这三件事**只依赖入参，不依赖页面状态**：
///
/// - `canUseAcademicImport`：一个纯布尔判定
/// - `blockingBody`：阻塞提示对话框的内容
/// - `unavailableMessage`：提示文案的归一
///
/// 一旦它们留在 State 里，就只能通过起一个完整页面、模拟点击才能测；
/// 抽成纯函数后，边界条件可以直接覆盖——而这里恰恰有真实的判断风险：
/// `supportsAcademicImport` 为真但 `loginUrl` 为空时，点进去会白屏。
void main() {
  School school({
    bool supportsAcademicImport = true,
    String mode = 'webview',
    String loginUrl = 'https://example.edu/login',
  }) {
    return School(
      id: 's1',
      name: '示例大学',
      shortName: '示例',
      supportsAcademicImport: supportsAcademicImport,
      supportsImageRecognition: true,
      login: SchoolLogin(
        mode: mode,
        loginUrl: loginUrl,
        successUrlPatterns: const ['grade'],
      ),
      version: 1,
      lessonTimeProfile: 'default',
    );
  }

  group('canUseAcademicImport', () {
    test('三个条件都满足时才可用', () {
      expect(canUseAcademicImport(school()), isTrue);
    });

    test('学校不支持教务导入时不可用', () {
      expect(
        canUseAcademicImport(school(supportsAcademicImport: false)),
        isFalse,
      );
    });

    test('登录模式不是 webview 时不可用', () {
      expect(canUseAcademicImport(school(mode: 'form')), isFalse);
    });

    test('登录地址为空时不可用（否则点进去是白屏）', () {
      // 这是最容易漏的组合：支持导入、模式也对，但地址是空的
      expect(canUseAcademicImport(school(loginUrl: '')), isFalse);
    });
  });

  group('unavailableMessage', () {
    test('空文案退化为通用提示，不显示空白', () {
      expect(unavailableMessage(''), isNot(isEmpty));
      expect(unavailableMessage('   '), isNot(isEmpty));
    });

    test('正常文案原样返回', () {
      expect(unavailableMessage('当前学校不支持导入'), '当前学校不支持导入');
    });
  });

  group('blockingBody', () {
    test('阻塞提示带进度指示与文案', () {
      final body = blockingBody('正在识别…');
      expect(body.message, '正在识别…');
      expect(body.showProgress, isTrue);
    });
  });
}
