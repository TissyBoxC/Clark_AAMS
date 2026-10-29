# 珂拉课程表 / Clark AAMS

一款使用 Flutter 开发的课程表应用，手机（Android / iOS）与电脑（Windows / macOS / Linux）共用一套界面与代码。应用内置浏览器内核，需要解析课表时直接在应用里打开学校教务系统，登录后一键读取整学期课表。

![Logo](assets/logo/logo.png)

## 功能特性

- 首次启动选择学校，当前内置 `金陵科技学院(JIT)`。
- 支持手动添加、编辑、删除、批量删除课程。
- 支持粘贴 JSON 批量导入，结构与应用导出的课程 JSON 保持一致。
- 内置浏览器内核：Windows 与 macOS 用系统自带内核打开学校页面，登录后一键读取课表，账号密码只交给学校网站，应用不保存。
- 支持截图识别与取件码两种备选导入方式。
- 导入后要求选择本学期第一周第一天，后续周次和日期自动顺延。
- 首页根据系统日期自动定位当前周，并高亮当天。
- 支持每门课程自定义颜色，内置多组颜色可选。
- 本地存储课程与设置，不依赖后端服务。
- 学校相关能力按目录拆分，后续可继续添加更多学校适配。

## 当前学校支持

| 学校 | 学校 ID | 教务系统导入 | 图片识别 |
| --- | --- | --- | --- |
| 金陵科技学院（JIT） | `jit` | 已支持 | 暂未支持 |

学校入口配置位于：

```text
lib/models/school.dart
```

JIT 相关实现位于：

```text
lib/schools/jit/
```

## 技术栈

| 类型 | 技术 |
| --- | --- |
| 跨端框架 | Flutter |
| 开发语言 | Dart |
| 目标平台 | Android、iOS、Windows、macOS、Linux |
| UI 框架 | Material 3 |
| 本地存储 | shared_preferences |
| 内置浏览器 | flutter_inappwebview（Windows/macOS 用系统内核） |
| 课程数据格式 | JSON |
| 平台工程 | Android Gradle、iOS Runner、Windows CMake、macOS/Linux Runner |
| 测试与检查 | flutter_test、flutter analyze |

核心实现：

- `ClassScheduleStore` 负责课程和应用设置的本地持久化。
- `ScheduleUtils` 负责周次、日期、节次时间和课程颜色计算。
- `lib/resources/` 集中放配色、字号、间距与文案，界面里不写死颜色和尺寸。
- `lib/services/academic_browser.dart` 负责把学校页面的课表读成课程；读取规则在 `lib/services/course_reader_script.dart`，加一所学校只需改这一个文件。

## 课程 JSON 格式

手动导入时粘贴 JSON 数组即可：

```json
[
  {
    "name": "高等数学",
    "startWeek": 1,
    "endWeek": 18,
    "dayOfWeek": 1,
    "startLesson": 1,
    "endLesson": 2,
    "location": "A101",
    "teacher": "张三",
    "weeks": [1, 2, 3, 4],
    "rawTime": "1-2节 (1-4周)",
    "colorValue": 4281472622
  }
]
```

字段说明：

| 字段 | 说明 |
| --- | --- |
| `name` | 课程名称 |
| `startWeek` / `endWeek` | 起止周 |
| `dayOfWeek` | 星期，1 到 7 分别表示周一到周日 |
| `startLesson` / `endLesson` | 起止节次 |
| `location` | 上课地点 |
| `teacher` | 任课教师，可选 |
| `weeks` | 精确上课周，可选；存在时优先用于单双周等场景 |
| `rawTime` | 教务系统原始时间文本，可选 |
| `colorValue` | 课程颜色 ARGB 整数，可选 |

## 项目结构

```text
lib/
  main.dart            启动与主题
  models/              数据模型
  resources/           配色、字号、间距、文案、主题
  screens/             页面（工作台、课表、导入、解析、我的）
  services/            本地存储、课表工具、内置浏览器读取
  widgets/             通用组件（卡片、按钮、课表网格）
  _legacy/             旧版界面留档，不参与编译
assets/
  logo/logo.png        应用内展示 logo
android/               Android 平台工程
ios/                   iOS 平台工程
windows/               Windows 平台工程
macos/                 macOS 平台工程
linux/                 Linux 平台工程
test/                  单元测试
```

## 开发环境

- Flutter SDK：`>= 3.11.5`
- Dart SDK：随 Flutter 安装
- Android Studio / Xcode：按目标平台安装

安装依赖：

```bash
flutter pub get
```

运行检查：

```bash
flutter analyze
flutter test
```

运行应用：

```bash
flutter run
```

构建 Android 调试包：

```bash
flutter build apk --debug
```

构建电脑端：

```bash
flutter build windows    # 需要 Visual Studio 的「使用 C++ 的桌面开发」工作负载
flutter build macos      # 需在 macOS 与 Xcode 环境下执行
flutter build linux      # 需在 Linux 与 GTK 开发环境下执行
```

构建 iOS 需在 macOS 与 Xcode 环境下执行：

```bash
flutter build ios
```

Windows 上内置浏览器依赖系统自带的 WebView2 运行时。Windows 11 已自带；
Windows 10 若未安装，应用会自动提示，也可以从微软官网单独安装。

## 新增学校适配

1. 学校列表由后端提供，`lib/models/school.dart` 只负责解析条目。
2. 需要专属读取规则的学校，在 `lib/services/course_reader_script.dart` 的规则表里加一条。
3. 页面上课表是普通表格的学校，用默认规则即可，不需要额外代码。
4. 读取结果统一转换成 `Course` 模型，界面不需要知道学校的差别。

## 应用信息

- 应用名称：珂拉课程表
- Android 包名：`io.github.tissyboxc`
- 作者：Provias
- 作者 QQ：1686886163
- 交流 QQ 群：1046151390
- 开源仓库：https://github.com/TissyBoxC/Clark_AAMS

## 许可证

本项目基于 GPL 许可证开源。详见 [LICENSE](LICENSE)。
