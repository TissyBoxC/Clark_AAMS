# 项目类与方法功能梳理

本文档梳理 `lib/` 目录下的主要业务类、数据模型、服务、页面组件和通用控件。重点章节放在 `lib/widget` 与 `lib/widgets`，这两处分别负责 Android 桌面小组件数据同步，以及 Flutter 内部复用控件。

## 总体结构

- `main.dart`：应用入口，初始化课程数据仓库、桌面小组件与登录会话。
- `config/`：后端地址配置。
- `models/`：课表、学校、用户、版本、节次时间、应用设置等纯数据模型。
- `services/`：本地持久化、后端接口、登录态、超星题目自动化、课程时间计算、桌面小组件桥接等业务服务。
- `screens/`：完整页面与页面内私有组件。
- `widget/`：Android 桌面小组件的数据构建、序列化、置顶请求。
- `widgets/`：Flutter 页面内复用控件，如顶部栏、课程编辑弹窗、统一 SnackBar。

## 核心数据流

1. `main()` 调用 `ClassScheduleStore.load()` 从 `SharedPreferences` 加载设置与课程。
2. `ClassScheduleStore` 持有 `AppSettingsModel` 和 `List<Course>`，页面通过 `ScheduleScope` 订阅变更。
3. 页面新增、导入、编辑、删除课程后，统一调用 `ClassScheduleStore` 的写方法保存到本地。
4. 课程或设置保存后，`ClassScheduleStore` 会触发 `WidgetService.updateWidget()`，把当前课表压缩为 Android 桌面小组件可消费的 JSON。
5. 导入、版本检查、认证、AI 解析等网络操作集中由 `ClarkBackendApi` 访问后端，并由 `AuthTokenStore` 注入登录码。

## `lib/widget` 详细说明

### `widget/widget_service.dart`

该文件是 Flutter 侧和 Android AppWidget 侧的主要数据桥。它不直接渲染 Android 小组件，而是把当前课表状态整理为稳定 JSON，写入 `HomeWidget` 存储，再通知 Android 的 `WidgetUpdateReceiver` 刷新。

#### `WidgetService`

- `updateWidget()`：公开刷新入口。仅 Android 平台执行；非 Android 直接返回。方法内部调用 `_buildPayload()` 生成 `_WidgetPayload`，将其 `toJson()` 后编码为 JSON，保存到 `course_widget_payload`，随后调用 `HomeWidget.updateWidget()` 通知原生 `WidgetUpdateReceiver` 更新。刷新失败会被捕获并静默忽略，避免桌面小组件异常影响主应用。
- `pinWidget()`：公开置顶小组件入口。仅 Android 平台执行；先通过 `HomeWidget.isRequestPinWidgetSupported()` 判断系统是否支持固定小组件，再调用 `HomeWidget.requestPinWidget()` 请求创建桌面小组件。返回值表示请求是否成功发出。
- `_buildPayload()`：读取本地设置与课程，按当前时间生成小尺寸和中尺寸两套面板状态。成功时返回包含 `generatedAt`、`small`、`medium` 的 `_WidgetPayload`；发生解析或读取异常时返回错误状态，保证 Android 侧仍能得到结构完整的数据。
- `_readSettings(SharedPreferences prefs)`：从 `class_schedule_settings` 读取 JSON，解析为 `AppSettingsModel`。空值、非 Map 或解析失败时回落到 `AppSettingsModel.defaults`。
- `_readCourses(SharedPreferences prefs)`：从 `class_schedule_courses` 读取课程 JSON 数组，逐项转换为 `Course`。非数组时返回空列表；每个课程使用数组下标作为 `fallbackId`，保证旧数据没有 id 时仍有可用标识。
- `_compareCourse(Course a, Course b)`：课程排序比较器，优先按星期排序，再按开始节次排序，最后按结束节次排序。它让 widget 中的今日课程按上课顺序展示。
- `_buildSmallState(List<Course> courses, AppSettingsModel settings, DateTime now)`：生成小尺寸小组件状态。它先筛选今天的课程；无课时返回 `empty`；有课但节次时间不可用时返回 `missingTimes`；今天课程都结束时返回 `finished`；否则返回 `ready` 并带上下一个未结束课程的 `_WidgetCourseView`。
- `_buildMediumState(List<Course> courses, AppSettingsModel settings, DateTime now)`：生成中尺寸小组件状态。它展示今日最多 4 条课程行；无课、缺少时间和正常状态分别对应 `empty`、`missingTimes`、`ready`。与小尺寸不同，中尺寸更偏向列表展示，不只关注下一节课。
- `_coursesForDate(List<Course> courses, AppSettingsModel settings, DateTime date)`：根据学期开始日期计算当前周，再按课程 `matchesWeek()` 与应用内星期值过滤出某一天的课程，并按 `_compareCourse()` 排序。
- `_nextCourse(List<Course> courses, AppSettingsModel settings, DateTime now)`：从已经按顺序排列的当天课程中寻找第一门尚未结束的课程。它把当前时间转换为分钟数，并通过 `_minuteForLesson()` 计算课程开始和结束边界。
- `_hasUsableTime(List<Course> courses, AppSettingsModel settings)`：判断课程列表中是否至少有一门课能同时取得开始节次和结束节次的有效时间。用于区分“今天有课但未配置节次时间”和“可以正常显示倒计时”。
- `_appDayOfWeek(DateTime date)`：将 Dart 的 `weekday` 转换为应用内部的星期值。当前实现与 Dart 一致，周一到周日为 1 到 7。
- `_minuteForLesson(AppSettingsModel settings, int lesson)`：从 `settings.startTimes` 中读取某节课的开始时间，解析 `HH:mm` 为当天分钟数。越界、空字符串、格式错误、小时分钟非法时返回 `null`。

#### `_WidgetPayload`

- 字段：`generatedAt`、`small`、`medium`。
- `toJson()`：输出 Android 小组件使用的顶层 JSON。`generatedAt` 使用 ISO-8601 字符串，`small` 和 `medium` 分别调用各自面板状态的 `toJson()`。
- 作用：作为 Flutter 到 Android 的稳定协议根对象，便于 Android 侧根据尺寸选择不同的展示数据。

#### `_WidgetPanelState`

- 字段：`status`、`title`、`subtitle`、`nextCourse`、`courseRows`。
- `toJson()`：序列化面板状态。`status` 使用枚举名称；`nextCourse` 为空时省略；`courseRows` 为空时省略，减少 Android 侧处理噪音。
- 作用：表达单个小组件面板当前该展示什么。它既可以表达正常课程，也可以表达无课、课程已结束、缺少节次时间、异常等空态或错误态。

#### `_WidgetStatus`

- `ready`：有可展示课程或课程列表。
- `empty`：当天没有课程。
- `finished`：当天课程存在，但都已结束。
- `missingTimes`：有课程，但无法从设置中解析出可用节次时间。
- `error`：构建 payload 过程中出现异常。

#### `_WidgetCourseView`

- 字段：`name`、`location`、`timeRange`、`startsIn`、`startsInMinutes`、`colorValue`。
- `fromCourse({required Course course, required AppSettingsModel settings, required DateTime now})`：把课程转换成小尺寸“下一节课”视图。它会计算课程开始、结束分钟，格式化时间段，并计算距离上课还有多久；如果课程已开始，`startsInMinutes` 会钳制为 0。
- `toJson()`：输出课程名称、地点、时间段、倒计时文案、倒计时分钟数和颜色值。Android 侧可直接使用这些字段渲染。
- 作用：专门服务小尺寸 widget，强调下一节课程和倒计时。

#### `_WidgetCourseRow`

- 字段：`name`、`location`、`timeRange`、`colorValue`。
- `fromCourse({required Course course, required AppSettingsModel settings})`：把课程转换成中尺寸列表行。它使用课程节次与设置中的开始时间构造时间范围，不计算倒计时。
- `toJson()`：输出列表行所需字段。
- 作用：专门服务中尺寸 widget，展示今日课程列表。

#### 顶层辅助函数

- `_formatMinute(int? minute)`：把分钟数转换为 `HH:mm`。输入为 `null` 或负数时返回空字符串；正常值按 24 小时制补零。
- `_formatDuration(int minute)`：把剩余分钟数转换为短文案。小于 1 小时显示分钟；整小时显示小时；非整小时显示“小时 + 分钟”的组合。

#### 小组件 JSON 形态

```json
{
  "generatedAt": "2026-05-17T12:00:00.000",
  "small": {
    "status": "ready",
    "title": "下一节课",
    "subtitle": "还有 20 分钟",
    "nextCourse": {
      "name": "课程名",
      "location": "教室",
      "timeRange": "08:00-08:45",
      "startsIn": "20分钟",
      "startsInMinutes": 20,
      "colorValue": 4280391411
    }
  },
  "medium": {
    "status": "ready",
    "title": "今日课程",
    "subtitle": "共 3 节",
    "courseRows": []
  }
}
```

## `lib/widgets` 详细说明

### `widgets/app_snack_bar.dart`

#### `AppSnackBar`

- `show(BuildContext context, String message, {Duration duration = const Duration(seconds: 2), SnackBarAction? action})`：统一显示页面提示。调用前会先 `hideCurrentSnackBar()`，避免多个提示连续堆叠；随后显示包含 `message`、`duration` 和可选 `action` 的 `SnackBar`。
- 使用场景：表单校验失败、导入失败、保存成功、权限或登录状态提醒。
- 设计意义：统一提示时长和替换行为，使页面不用重复编写 ScaffoldMessenger 逻辑。

### `widgets/course_form_dialog.dart`

#### `CourseFormDialog`

- 构造参数：`course`、`maxWeeks`、`lessonCount`。`course` 为空表示新增课程，非空表示编辑课程；`maxWeeks` 决定周次下拉范围；`lessonCount` 决定节次下拉范围。
- `createState()`：创建 `_CourseFormDialogState`，由状态类管理输入框、下拉值和保存逻辑。
- 作用：提供课程新增和编辑的统一弹窗，输出一个新的 `Course` 对象给调用页面。

#### `_CourseFormDialogState`

- `initState()`：根据传入课程初始化名称、地点、起止周、星期、起止节次。新增时使用默认值；编辑时回填原课程。
- `dispose()`：释放课程名和地点的 `TextEditingController`。
- `build(BuildContext context)`：构建 `AlertDialog`，包含课程名称、起止周、星期、起止节次、地点，以及取消/保存按钮。周次和节次通过 `_Dropdown` 渲染，保证选项范围与当前配置同步。
- `_save()`：表单核心逻辑。先校验课程名不能为空，再校验起始周不大于结束周、起始节次不晚于结束节次；通过后构造 `Course` 并 `Navigator.pop()` 返回。编辑课程时保留原 id、教师、原始时间、活跃周和颜色。
- `_toast(String message)`：使用 `AppSnackBar.show()` 显示校验错误。

#### `_Dropdown<T>`

- 构造参数：`value`、`items`、`onChanged`。
- `build(BuildContext context)`：包装 `DropdownButtonFormField<T>`，使用统一的边框样式和紧凑布局。
- 非空保护：内部 `onChanged` 收到 `null` 时不向上传递，避免调用侧处理无意义状态。

### `widgets/top_bar.dart`

#### `TopBar`

- 构造参数：`title`、`leading`、`trailing`、`titleIcon`。
- `build(BuildContext context)`：使用 `SafeArea` 和固定高度容器构建顶部栏。标题居中，左侧和右侧分别放置可选操作；如果传入 `titleIcon`，会与标题同行展示。
- 作用：替代默认 `AppBar`，提供项目内一致的页面头部样式，同时兼容需要自定义返回按钮、菜单按钮、右侧动作的页面。

## 入口与配置

### `main.dart`

#### `main()`

初始化 Flutter 绑定，加载 `ClassScheduleStore`，异步触发桌面小组件刷新和 `AuthSession` 初始化，最后用 `ClassScheduleApp` 启动应用。

#### `ClassScheduleApp`

- 构造参数：`store`。
- `build(BuildContext context)`：创建 `MaterialApp`，挂载 `ScheduleScope`，配置主题、首页和全局 Store 访问入口。

### `config/backend_config.dart`

#### `BackendConfig`

- `baseUrl`：后端服务基础地址。
- `uri(String path, [Map<String, Object?>? queryParameters])`：把路径和可选查询参数拼接成 `Uri`。空值参数会被忽略，避免生成无意义 query。

## 数据模型

### `models/app_settings.dart`

#### `AppSettingsModel`

- `defaults`：应用默认设置，包括最大周数、单节课时长、首次启动标记、默认学期日期和学校选择状态。
- `unspecifiedSchoolId`：表示用户选择“不指定学校”的特殊 id。
- `hasSpecificSchool`：判断是否选择了真实学校。
- `copyWith(...)`：复制设置并覆盖指定字段，用于不可变状态更新。
- `toJson()`：将设置写入本地存储。
- `fromJson(Map<String, Object?> json)`：从本地 JSON 恢复设置，缺失字段使用默认值。
- `_asInt(Object? value)`：兼容 int、num、String 的整型解析。
- `_legacyTermStartDate(...)`：旧版本学期开始日期兼容入口，目前返回空字符串。

### `models/app_version.dart`

#### `AppVersionInfo`

- `primaryDownloadSource`：优先返回标记为 `primary` 的下载源，没有主下载源时返回第一个。
- `fromJson(Map<String, Object?> json)`：解析后端版本检查响应，包含当前版本、最新版本、是否强制更新、更新说明、下载源等。
- `_asInt(Object? value)`：兼容多种数值类型解析 build 号。

#### `DownloadSource`

- `fromJson(Map<String, Object?> json)`：解析下载源类型、展示名称、地址、主源标记和说明。

### `models/clark_user.dart`

#### `ClarkUser`

- `isAuthenticated`：根据用户 id 是否大于 0 判断当前用户是否为已认证用户。
- `displayName`：优先使用用户名，其次使用邮箱，最后回落到登录码或默认用户文案。
- `maskedLoginCode`：对登录码做脱敏展示，避免完整凭证直接暴露在 UI。
- `fromJson(Map<String, Object?> json)`：解析后端用户数据。
- `_asInt(Object? value)`：解析数值字段，例如辅助次数。

### `models/course.dart`

#### `Course`

- `duration`：计算课程跨越的节次数。
- `weekText`：把连续周或离散周转换为展示文本。
- `matchesWeek(int week)`：判断课程是否在指定周生效。优先使用 `activeWeeks`；为空时使用 `startWeek` 到 `endWeek` 的连续范围。
- `copyWith(...)`：复制课程并覆盖部分字段。
- `toJson({bool includeId = true})`：将课程序列化，支持导出时省略 id。
- `fromJson(Map<String, Object?> json, {int? fallbackId})`：兼容本地、后端和旧字段名解析课程，例如 `day`、`startSection`、`position`。
- `_asInt(Object? value)`：兼容 int、num、String。
- `_asIntList(Object? value)`：解析周次数组，去重、排序后返回。

### `models/school.dart`

#### `School`

- `fromJson(Map<String, Object?> json)`：解析学校基础信息、别名、图标、教务系统登录配置等。
- `_asMap(Object? value)`：把动态 Map 安全转换为 `Map<String, Object?>`。
- `_asInt(Object? value)`：解析学校 id 等数值字段。

#### `SchoolLogin`

保存教务系统登录相关配置，例如登录地址、成功地址匹配规则、学生 id 提取规则等。它服务于 `AcademicImportPage` 的 WebView 导入流程。

- `fromJson(Map<String, Object?> json)`：解析登录模式、登录地址和成功 URL 匹配规则。

### `models/school_lesson_times.dart`

#### `LessonTime`

- `fromJson(Map<String, Object?> json)`：解析某一节课的开始时间。
- `_asInt(Object? value)`：兼容数值解析。

#### `SchoolLessonTimes`

- `fromJson(Map<String, Object?> json)`：解析学校或通用节次时间配置。
- `toStartTimes({int minimumLength = 13})`：把后端按节次给出的时间列表转换为应用本地 `startTimes` 数组，保证至少包含指定长度。
- `firstConfiguredStartTime`：返回第一个非空开始时间，用于展示或判断配置是否有效。

## 服务层

### `services/auth_session.dart`

#### `AuthSession`

- `instance`：全局登录会话单例。
- `initialize()`：读取本地登录码并尝试拉取当前用户；已经初始化时直接返回。
- `refresh()`：重新拉取当前用户状态，登录码失效时清理本地凭证。
- `hasUsableCredential()`：判断内存用户或本地存储是否有可用登录码。
- `debugSnapshot()`：生成登录态调试快照。
- `loginByEmail({qqEmail, password})`：邮箱密码登录，成功后保存用户和登录码。
- `loginByCode(String loginCode)`：使用登录码登录。
- `register({username, password, qqEmail})`：注册并接收后端返回用户。
- `logout()`：调用后端退出并清空本地登录码。
- `_acceptUser(ClarkUser user)`：统一接收用户对象，保存登录码并通知 UI。
- `_setBusy(bool value)`：维护忙碌状态并通知监听者。

#### `AuthDebugSnapshot`

- `toLogLines(String prefix)`：将用户、登录码、存储诊断信息格式化成日志行，便于排查安全存储或 SharedPreferences 回退问题。

### `services/auth_token_store.dart`

#### `AuthTokenStore`

- `instance`：全局凭证存储单例。
- `readLoginCode()`：优先读内存缓存，再读安全存储，最后读 SharedPreferences 回退值。
- `saveLoginCode(String loginCode)`：保存规范化后的登录码；空登录码会触发清理。
- `clearLoginCode()`：清理内存、安全存储和 SharedPreferences 中的登录码。
- `authHeaders({bool contentTypeJson = true})`：生成请求头，默认带 JSON Content-Type；有登录码时添加认证头。
- `diagnostics()`：返回存储层诊断信息。
- `_mask(String value)`：脱敏凭证。

#### `AuthTokenDiagnostics`

记录 secure storage、SharedPreferences、缓存值、错误信息等，供登录问题排查。

### `services/chaoxing_question_automation.dart`

#### `ChaoxingQuestion`

- `fromJson(Map<String, Object?> json, int index)`：从 WebView JavaScript 提取的数据中解析题号、题干、题型、图片和选项。

#### `ChaoxingAnswerClickResult`

- `fromJson(Object? value)`：解析注入 JS 后返回的点击结果，包含是否成功、消息和调试日志。

#### `ChaoxingQuestionAutomation`

- `collectQuestionsJs`：注入 WebView 的脚本，用于跨 frame 查找题目容器、抽取题干、题号、题型、图片和选项。
- `answerJs`：注入 WebView 的脚本模板，用于按题号和选项字母定位并点击答案。
- `parseQuestions(Object? value)`：解析 JavaScript 返回值，过滤无效项并去重。
- `extractAnswerLetter(Object? aiResult)`：从后端 AI 分析结果中提取 A/B/C/D 等选项字母。
- `answerQuestionScript(String number, String letter)`：生成针对某题号和答案字母的实际点击脚本。
- `_decodeJavaScriptJson(Object? value)`：兼容 WebView 返回的对象、字符串和二次 JSON 编码字符串。
- `_uniqueQuestions(List<ChaoxingQuestion> questions)`：按题号和题干生成 key，去除重复题目。

### `services/clark_backend_api.dart`

#### `ClarkBackendApi`

- `instance`：默认后端 API 单例。
- `getSchools()`：获取学校列表并解析为 `School`。
- `getSchool(String schoolId)`：获取单个学校配置。
- `getSchoolLessonTimes(String schoolId)`：获取指定学校节次时间。
- `getGeneralLessonTimeProfiles()`：获取通用节次时间模板。
- `importCourses({schoolId, cookie, studentId, successUrl})`：将教务系统登录会话提交给后端并返回课程列表。
- `recognizeCourseImages(List<File> images)`：上传课表图片进行 OCR，返回取件码和识别出的课程。
- `getCoursesByPickupCode(String code)`：通过 8 位取件码拉取课程。
- `checkVersion({platform, currentVersion, currentBuild, channel})`：检查应用版本更新。
- `analyzeQuestion({questionType, questionContent, options})`：提交超星题目给后端分析答案，使用更长超时时间。
- `register(...)`、`loginByEmail(...)`、`loginByCode(...)`、`currentUser()`、`logout()`：用户认证相关接口。
- `_get(String path)`：带认证头的 GET 请求封装。
- `_post(String path, Map<String, Object?> body, {Duration? timeout})`：带认证头的 POST 请求封装。
- `_unwrap(http.Response response)`：统一解析后端响应，处理 HTTP 错误、JSON 格式错误和业务 code 非 0。
- `_responseErrorMessage(http.Response response, String fallback)`：从错误响应中提取可读 message。
- `_imageContentType(String path)`：根据文件内容和扩展名推断图片 MIME。
- `_fileHeaderBytes(String path)`：读取文件头用于 MIME 判断。
- `_mimeTypeFromExtension(String path)`：在内容推断失败时按扩展名回退。
- `_parseCourseList(List coursesJson)`：批量解析课程并分配 fallback id。
- `_parseUser(Object? data)`：解析后端用户对象。

#### `CoursePickupResult`

保存 OCR 导入返回的 `pickupCode` 和 `courses`。

#### `ApiException`

- `toString()`：返回错误消息，方便 UI 直接展示异常。

### `services/class_schedule_store.dart`

#### `ClassScheduleStore`

- `load()`：从 `SharedPreferences` 读取设置和课程，修正当天不是周一时的旧学期日期，并返回 Store 实例。
- `markLaunched()`：标记应用已完成首次启动。
- `selectSchool(String schoolId)`：保存所选学校并结束首次启动。
- `useOtherImportMethods()`：保存“不指定学校”，允许用户直接使用其他导入方式。
- `resetSchoolSelection()`：清空学校选择并回到首次启动状态。
- `updateSettings(AppSettingsModel next)`：保存设置并刷新 widget。
- `resetSettings()`：恢复默认设置并刷新 widget。
- `clearCourses()`：清空课程列表并刷新 widget。
- `addCourse(Course course)`：添加课程并分配新 id。
- `importCourses(List<Course> courses)`：批量导入课程，重新分配连续 id。
- `updateCourse(int id, Course course)`：按 id 替换课程。
- `deleteCourse(int id)`：删除单门课程。
- `deleteCourses(Set<int> ids)`：批量删除课程。
- `syncMaxWeeks({required int oldMaxWeeks, required int newMaxWeeks})`：调整最大周数时同步课程周范围。
- `exportCoursesJson()`：导出课程 JSON，通常用于批量编辑弹窗。
- `_saveSettings()`：写入设置、通知监听者、刷新小组件。
- `_saveCourses()`：写入课程、通知监听者、刷新小组件。
- `_nextCourseId()`：计算下一个课程 id。

### `services/course_json_importer.dart`

#### `CourseJsonImporter`

- `parse(String jsonText)`：解析用户粘贴的课程 JSON。要求顶层为数组，逐项转换为 `Course`，并校验课程名、周次、星期和节次范围，格式不合法时抛出 `FormatException`。

### `services/home_widget_updater.dart`

#### `HomeWidgetUpdater`

- `update()`：通过 `MethodChannel` 调用原生小组件刷新。非 Android 平台直接返回。
- `pin([String variant = 'themed_2x2'])`：通过原生通道请求固定小组件，返回是否成功。

### `services/lesson_time_defaults.dart`

#### `LessonTimeSetupDefaults`

封装课程时间设置页的初始值，包括开始时间数组、可选模板、默认选中模板等。

#### `LessonTimeDefaults`

- `resolve(ClassScheduleStore store, {int lessonCount = 13})`：生成节次时间默认值。优先使用本地已配置时间；其次尝试所选学校的时间；最后加载通用模板。
- `_fitLength(List<String> value, int lessonCount)`：把时间数组裁剪或补齐到指定长度。
- `_hasConfiguredTimes(List<String> times)`：判断时间数组中是否存在非空时间。

### `services/schedule_scope.dart`

#### `ScheduleScope`

- `of(BuildContext context)`：从 widget 树中取得 `ClassScheduleStore`。找不到时触发断言，说明页面未被正确挂载在 `ScheduleScope` 下。

### `services/schedule_utils.dart`

#### `ScheduleUtils`

- `courseColors`：课程颜色池。
- `localDateLabel(DateTime date)`：生成本地日期标签。
- `termStartDate(AppSettingsModel settings)`：解析学期开始日期，失败时按旧字段回退。
- `currentWeek(AppSettingsModel settings, DateTime today)`：计算当前教学周，并限制在 1 到最大周数。
- `weekMonday(AppSettingsModel settings, int week)`：计算某教学周的周一日期。
- `formatDate(DateTime date)`：格式化日期。
- `timeRange(AppSettingsModel settings, Course course)`：根据节次开始时间和单节课时长生成课程时间范围。
- `lessonCount(AppSettingsModel settings, [List<Course>? courses])`：计算需要展示的最大节次数，兼顾配置和实际课程。
- `endTime(String startTime, int durationMinutes)`：根据开始时间和持续分钟数计算结束时间。
- `colorForCourse(Course course)`：优先使用课程自定义颜色，否则按课程名生成默认颜色。
- `defaultColorForName(String name)`：根据课程名哈希稳定选择颜色。
- `isTimeListValid(List<String> times)`：校验节次时间列表是否为合法 `HH:mm`。

## 页面层

### `screens/about_page.dart`

#### `AboutPage` / `_AboutPageState`

- `initState()`：进入页面后触发版本信息加载。
- `build(BuildContext context)`：渲染关于页面、当前版本、最新版本和更新入口。
- `_loadVersionInfo()`：调用后端版本检查并更新页面状态。
- `_openUpdateUrl()`：打开主下载源或发布页。

#### `_VersionPanel`

- `build(BuildContext context)`：展示版本状态、当前版本、最新版本、更新说明和更新按钮。
- `_statusText()`：根据是否强制更新、是否有更新生成状态文案。
- `_versionLabel(String version, int? build)`：组合版本名和 build 号。

#### `_AboutRow`

- `build(BuildContext context)`：渲染一行 label/value 信息。

### `screens/academic_import_page.dart`

#### `AcademicImportPage` / `_AcademicImportPageState`

- `initState()`：创建 WebViewController，配置导航代理并加载学校登录页。
- `build(BuildContext context)`：展示 WebView、顶部栏和导入进度。
- `_setLoading(bool value)`：维护页面加载状态。
- `_handlePossibleLogin(String url)`：发现成功登录 URL 后读取 cookie 和学生 id，调用后端导入课程并返回上一页。
- `_matchesSuccessUrl(String url)`：判断当前 URL 是否匹配学校成功登录规则。
- `_wildcardMatch(String pattern, String value)`：支持通配符的 URL 匹配。
- `_readCookies()`：从当前页、登录页、成功页相关域名读取 cookie 并拼接。
- `_extractStudentId(String url)`：优先从 URL 提取学生 id，失败时执行 JavaScript 从页面 DOM 中读取。
- `_decodeJavaScriptString(Object? value)`：解码 WebView JavaScript 返回的字符串。

#### `_ImportStatusBar`

- `build(BuildContext context)`：显示当前登录、加载或导入状态。

### `screens/app_settings_page.dart`

#### `AppSettingsPage` / `_AppSettingsPageState`

- `initState()`、`didChangeDependencies()`：初始化最大周数输入框并读取 Store。
- `dispose()`：释放控制器。
- `build(BuildContext context)`：展示学校设置、学期与节次时间设置、最大周数、重置入口。
- `_configureTermAndTimes()`：进入 `TermLessonSetupPage`，保存返回的学期开始日期、单节课时长和节次时间。
- `_saveMaxWeeks()`：校验并保存最大周数，必要时询问是否同步课程周范围。
- `_showSyncDialog()`：确认是否调整已有课程周次。
- `_confirmResetSchoolSelection()`：确认重新选择学校。
- `_confirmReset()`：确认重置全部设置。
- `_toast(String message)`：显示提示。

#### 页面私有组件

- `_SettingRow.build()`：渲染通用设置行。
- `_SchoolSettingRow.build()`：渲染学校选择状态与重新选择按钮。
- `_SchoolInfoText.build()`：根据学校 id 展示学校状态。
- `_NumberField.build()`：封装数字输入框。

### `screens/auth_page.dart`

#### `_AuthMode`

定义邮箱登录、登录码登录、注册三种表单模式。

#### `AuthPage` / `_AuthPageState`

- `dispose()`：释放输入控制器。
- `build(BuildContext context)`：根据认证状态展示用户面板或登录/注册表单。
- `_submit()`：按当前模式调用 `AuthSession` 的登录或注册方法。
- `_logout()`：退出登录。
- `_showError(String message)`：显示认证错误。

#### `_AuthForm`

- `build(BuildContext context)`：渲染分段模式切换、用户名、邮箱、密码、登录码输入和提交按钮。
- 私有校验逻辑：校验必填字段，并限制邮箱必须是 QQ 邮箱。

#### `_UserPanel`

- `build(BuildContext context)`：展示用户昵称、登录码、邮箱状态、做题辅助次数，以及复制登录码、退出登录等操作。

#### `_AccountLine`

- `build(BuildContext context)`：渲染账户信息行。

### `screens/chaoxing_homework_page.dart`

#### `ChaoxingHomeworkPage` / `_ChaoxingHomeworkPageState`

- `initState()`：初始化 WebView，加载超星页面并维护加载状态。
- `build(BuildContext context)`：展示 WebView 和可拖动的自动化面板。
- `_setLoading(bool value)`：维护 WebView 加载状态。
- `_refreshPageIdentity()`：读取页面标题和 URL，更新面板当前页面信息。
- `_startAnswering()`：完整自动答题流程。它校验登录凭证，执行题目采集 JS，逐题调用后端分析答案，再注入点击脚本，并累计成功、失败和状态信息。
- `_requestStop()`：请求停止当前答题流程。
- `_decodeJavaScriptString(Object? value)`：解码 WebView 返回字符串。

#### 自动化面板组件

- `_FloatingAutomationPanel.build()`：根据折叠状态构建悬浮面板。
- `_buildCollapsed(ColorScheme colorScheme)`：构建折叠态。
- `_buildFull(BuildContext context)`：构建完整态，展示页面信息、题目统计、状态和操作按钮。
- `_InfoLine.build()`：展示页面标题、URL 等键值信息。
- `_Metric.build()`：展示题目数量、已处理、成功、失败等统计值。

### `screens/course_settings_page.dart`

#### `CourseSettingsPage` / `_CourseSettingsPageState`

- `build(BuildContext context)`：展示课程列表、导入菜单、批量删除模式和悬浮新增按钮。
- `_goBack()`：根据导航栈返回，不能返回时进入首页。
- `_showCourseDialog([Course? course])`：打开课程新增或编辑弹窗。
- `_showCourseColorDialog(Course course)`：打开课程颜色选择弹窗。
- `_confirmDelete(Course course)`：确认删除单门课程。
- `_confirmBatchDelete()`：确认批量删除选中课程。
- `_showBatchAddDialog()`：打开 JSON 批量导入/导出弹窗。
- `_showImportMethodSheet()`：展示 OCR、取件码、教务系统导入入口。
- `_importFromOcr()`：选择课表图片，上传后端 OCR，得到课程和取件码。
- `_showPickupCodeResult(String pickupCode)`：展示 OCR 生成的取件码。
- `_importFromPickupCode()`：输入取件码并导入对应课程。
- `_showBlockingMessage(String message)`：显示不可交互的等待弹窗。
- `_canUseAcademicImport(School school)`：判断学校是否配置了教务导入能力。
- `_loadSelectedSchool(String schoolId)`：加载当前学校配置。
- `_importFromAcademicSystem(School? school)`：进入 WebView 教务导入页并接收课程。
- `_resetSchoolSelection()`：回到欢迎页重新选择学校。
- `_showUnavailable(String message)`：显示不可用或错误提示。
- `_importCoursesAndSetTermStart(List<Course> courses)`：导入课程前后引导设置学期开始日期和节次时间。
- `_withDefaultColors(List<Course> courses)`：为没有颜色的课程分配默认颜色。
- `_askTermAndLessonTimesAfterImport(...)`：打开导入后的学期与节次设置页。

#### 课程设置页枚举

- `_CourseMenu`：顶部菜单项，包含导入课表、批量添加、批量删除。
- `_ImportMethod`：导入方式，包含 OCR 图片识别、取件码、教务系统。
- `_CourseItemMenu`：单个课程卡片菜单，包含编辑、改色、删除。

#### 课程设置页面私有组件

- `_CourseListCard.build()`：渲染单个课程卡片，支持批量选择、编辑、改色、删除。
- `_InfoLine.build()`：展示课程的周次、星期节次、地点等信息。
- `_BatchDeleteBar.build()`：渲染批量删除工具条。
- `_BatchAddDialogState.dispose()`：释放 JSON 输入控制器。
- `_BatchAddDialogState.build()`：构建批量导入弹窗。
- `_exportJson()`：把当前课程 JSON 复制到剪贴板。
- `_showHelp()`：显示 JSON 导入格式说明。
- `_save()`：解析 JSON 并返回课程列表。
- `_toast(String message)`：显示弹窗内提示。
- `_CourseColorDialog.build()`：渲染单门课程颜色选择。
- `_ImportedCourseColorsDialogState.initState()`：初始化导入课程的颜色映射。
- `_ImportedCourseColorsDialogState.build()`：让用户批量确认或调整导入课程颜色。
- `_ColorGrid.build()`：渲染颜色池。
- `_ColorDot.build()`：渲染单个颜色圆点。
- `_PickupCodeDialogState.dispose()`：释放取件码输入框。
- `_PickupCodeDialogState.build()`：输入并校验 8 位取件码。

### `screens/home_page.dart`

#### 顶层函数

- `_weekLabel(int week)`：生成教学周标签。
- `_lessonRangeLabel(int startLesson, int endLesson)`：生成节次范围标签。

#### `HomePage` / `_HomePageState`

- `build(BuildContext context)`：根据 Store 状态决定是否跳转欢迎页，并构建首页、课表、我的三个 Tab。
- `_promptForTermStartDate()`：在缺少学期开始日期时引导用户设置。
- `_checkAppVersion()`：进入首页后检查版本更新。
- `_showUpdateDialog(AppVersionInfo version)`：展示更新提示。
- `_openDownload(AppVersionInfo version)`：打开下载源或发布页。

#### 首页私有组件

- `_IllustratedBottomBar.build()`：构建带图片的底部导航。
- `_NavArtSpec`：描述底部导航图片资源和选中状态。
- `_NavArtButton.build()`：渲染单个底部导航按钮。
- `_HomeTab.build()`：首页概览，包括当前周、今日课程和统计卡片。
- `_HomeHeroCard.build()`：展示日期、教学周和主要状态。
- `_SoftPanel.build()`：通用柔和面板容器。
- `_MetricTile.build()`：统计指标卡片。
- `_SectionTitle.build()`：分区标题。
- `_EmptyTodayCard.build()`：今日无课空态。
- `_TodayCourseTile.build()`：今日课程列表项。
- `_ScheduleTab.build()`：课表页，组合头部和课程网格。
- `_ScheduleHeaderCard.build()`：展示当前周和周切换操作。
- `_MineTab.build()`：我的页面，展示账号入口、设置、关于、桌面小组件、超星功能等。
- `_AuthEntryButton.build()`：登录入口按钮。
- `_MineProfileCard.build()`：我的页资料卡。
- `_MineAvatar.build()`：头像展示。
- `_MineActionTile.build()`：我的页功能入口。
- `_WeekHeader.build()`：课表顶部周次头。
- `_DayHeader.build()`：课表中的日期列头。
- `_ScheduleTable.build()`：构建周课表网格。
- `_DayColumn.build()`：构建单日课程列。
- `_CourseBlock.build()`：构建课表中的课程块。
- `_showLessonInfo(...)`：点击课程块后展示课程详情。

### `screens/term_lesson_setup_page.dart`

#### `TermLessonSetupResult`

保存设置页返回值：学期开始日期、单节课时长、节次开始时间。

#### `TermLessonSetupPage` / `_TermLessonSetupPageState`

- `initState()`：初始化日期、单节课时长和节次时间数组。
- `build(BuildContext context)`：构建学期开始日期、课程时长、节次时间列表和模板按钮。
- `_pickTermStartDate()`：打开日期选择器设置学期第一周周一。
- `_save()`：整理输入，裁剪尾部空节次时间并返回 `TermLessonSetupResult`。
- `_applyLessonTimeProfile(SchoolLessonTimes profile)`：应用学校或通用节次时间模板。
- `_pickLessonTime(int lessonIndex)`：打开底部滚轮选择某节课的开始时间。
- `_formatPickedTime(int period, int hour, int minute)`：将上午/下午选择和小时分钟转换为 `HH:mm`。

#### 设置页私有组件

- `_LessonTimeProfileButton.build()`：渲染可应用的节次模板。
- `_LessonTimeProfileButton._trimLeadingZero(String value)`：展示时间时去掉前导 0。
- `_PickedTime`：保存滚轮选择的小时、分钟和最终字符串。
- `_WheelColumn.build()`：构建滚轮选择列。
- `_SetupPanel.build()`：设置页通用面板容器。

### `screens/welcome_page.dart`

#### `WelcomePage` / `_WelcomePageState`

- `initState()`：开始加载学校列表并监听搜索框变化。
- `dispose()`：释放搜索框控制器。
- `build(BuildContext context)`：展示搜索框、学校列表、手动/其他导入入口。
- `_filterSchools(List<School> schools)`：按学校名称或别名过滤。
- `_reloadSchools()`：重新请求学校列表。

#### 欢迎页私有组件

- `_LoadError.build()`：展示学校列表加载失败与重试按钮。
- `_EmptySearchResult.build()`：展示搜索无结果空态。
- `_SchoolTile.build()`：渲染学校选项卡片。
