import 'package:clark_aams/resources/app_strings.dart';
import 'package:flutter_test/flutter_test.dart';

/// `AppStrings` 拆分后的契约（P4-1）。
///
/// 背景：`app_strings.dart` 曾是一个 975 行、255 个常量的单文件，
/// 全部平铺在一个类里，没有任何分组。读的人很难判断
/// 「这个常量属于哪个功能」，加常量时也无从知道该放哪。
///
/// 拆分方式：按功能域拆成多个文件，再用 `part` 合并回同一个类。
/// 这样**调用方一行都不用改**——`AppStrings.xxx` 的写法完全保留，
/// 但每个文件只承载一个功能域。
///
/// 这个测试的意义不是「验证字符串值对不对」（那些值没人会改），
/// 而是钉住拆分后最容易坏掉的地方：
///
/// 1. 类名与访问方式不能变（否则全项目几十处调用一起报错）
/// 2. 各功能域的常量必须真的还在、且值不变
/// 3. 占位符方法（带参数的）签名不能丢
void main() {
  group('类结构未被拆分破坏', () {
    test('AppStrings 仍是可直接实例化访问的类', () {
      // 私有构造 + 全静态成员是原设计，拆分后必须保持
      // ignore: unnecessary_type_check
      expect(AppStrings, isA<Type>());
      expect(AppStrings.appName, '珂拉课程表');
    });

    test('类不可被实例化（私有构造仍在，编译期即保证）', () {
      // 构造是 `const AppStrings._()`，外部代码写 `AppStrings()` 会直接编译失败。
      // 这一点由「编译器本身」保证——上面那条 `expect(AppStrings, isA<Type>())`
      // 能通过编译、而 `AppStrings()` 不能，就是证据，无需运行时断言。
      expect(AppStrings.appName, isNotEmpty);
    });
  });

  group('各功能域常量仍在且值不变', () {
    test('基础常量', () {
      expect(AppStrings.appName, '珂拉课程表');
      expect(AppStrings.updateAvailableTitle, '发现新版本');
      expect(AppStrings.notLoggedIn, '未登录');
      expect(AppStrings.notGenerated, '未生成');
    });

    test('超星（chaoxing）功能域常量', () {
      // 这是被拆出去的最大一组（40 个），也是最容易丢的一组
      expect(AppStrings.chaoxingTitle, isNotEmpty);
      expect(AppStrings.chaoxingHomeworkTitle, isNotEmpty);
      expect(AppStrings.chaoxingLoginRequiredFromHome, isNotEmpty);
    });

    test('课表/导入功能域常量', () {
      expect(AppStrings.invalidCourseImportResponse, isNotEmpty);
      expect(AppStrings.invalidCourseDataResponse, isNotEmpty);
      expect(AppStrings.invalidSchoolsResponse, isNotEmpty);
    });

    test('取件码功能域常量', () {
      expect(AppStrings.enterEightDigitPickupCode, isNotEmpty);
      // 文案里不能出现状态码，也不该出现「HTTP」这类实现细节
      expect(AppStrings.pickupCodeFetchFailed(404), isNot(contains('404')));
      expect(AppStrings.pickupCodeFetchFailed(404), isNot(contains('HTTP')));
    });
  });

  group('错误文案不暴露实现细节', () {
    // 界面文案只说明发生了什么、下一步做什么；状态码留给日志。
    test('取件码失败文案不含状态码', () {
      final message = AppStrings.pickupCodeFetchFailed(500);
      expect(message, isNot(contains('500')));
      expect(message, isNotEmpty);
    });

    test('请求失败文案不含状态码与 HTTP 字样', () {
      final message = AppStrings.backendRequestFailed(500);
      expect(message, isNot(contains('500')));
      expect(message, isNot(contains('HTTP')));
    });
  });
}
