# 珂拉课程表 / Clark AAMS

一款使用 Flutter 开发的本地课程表应用，面向 Android 与 iOS。应用支持手动维护课表、JSON 导入、按学校拆分的教务系统导入能力，并已内置金陵科技学院（JIT）适配。

![Logo](assets/logo/logo.png)

## 功能特性

- 首次启动选择学校，当前内置 `金陵科技学院(JIT)`。
- 支持手动添加、编辑、删除、批量删除课程。
- 支持粘贴 JSON 批量导入，结构与应用导出的课程 JSON 保持一致。
- 支持金陵科技学院教务系统 WebView 登录导入。
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
| 目标平台 | Android、iOS |
| UI 框架 | Material 3 |
| 本地存储 | shared_preferences |
| 教务系统登录 | webview_flutter |
| HTML 解析 | html |
| 课程数据格式 | JSON |
| 平台工程 | Android Gradle、iOS Runner |
| 测试与检查 | flutter_test、flutter analyze |

核心实现：

- `ClassScheduleStore` 负责课程和应用设置的本地持久化。
- `ScheduleUtils` 负责周次、日期、节次时间和课程颜色计算。
- `lib/schools/<school_id>/` 按学校拆分教务系统导入逻辑。
- JIT 适配使用 WebView 登录教务系统，再解析课表 HTML 并转换为应用通用课程模型。

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
  main.dart
  models/              数据模型
  screens/             页面
  services/            本地存储、课表工具、作用域
  schools/
    jit/               金陵科技学院教务系统导入与解析
  widgets/             通用组件
assets/
  logo/logo.png        应用内展示 logo
android/               Android 平台工程
ios/                   iOS 平台工程
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

构建 iOS 需在 macOS 与 Xcode 环境下执行：

```bash
flutter build ios
```

## 新增学校适配

1. 在 `lib/models/school.dart` 中添加学校配置。
2. 在 `lib/schools/<school_id>/` 下新增该学校的导入页面、解析器和导入适配器。
3. 在课程导入入口中按学校 ID 分发到对应导入实现。
4. 保持最终输出为应用通用 `Course` 模型或兼容课程 JSON。

## 应用信息

- 应用名称：珂拉课程表
- Android 包名：`io.github.tissyboxc`
- 作者：Provias
- 作者 QQ：1686886163
- 交流 QQ 群：1046151390
- 开源仓库：https://github.com/TissyBoxC/Clark_AAMS

## 许可证

本项目基于 GPL 许可证开源。详见 [LICENSE](LICENSE)。
