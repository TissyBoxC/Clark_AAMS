import 'chaoxing_scripts.dart';

class AppStrings {
  const AppStrings._();

  static const appName = '珂拉课程表';
  static const updateAvailableTitle = '发现新版本';
  static const notLoggedIn = '未登录';
  static const notGenerated = '未生成';
  static const unknownQuestionType = '未知题型';
  static const invalidSchoolsResponse = '没能读到学校列表，请稍后重新打开这一页。';
  static const invalidSchoolConfigResponse = '没能读到这所学校的作息，请换一所学校或稍后再试。';
  static const invalidSchoolLessonTimesResponse = '没能读到上课时间，请稍后重试。';
  static const invalidGeneralLessonTimesResponse = '没能读到上课时间，可以手动填写每节课的开始时间。';
  static const invalidCourseImportResponse = '课表没有导入成功，请稍后再试一次。';
  static const invalidCourseDataResponse = '课表读取不完整，请下拉刷新。';
  static const selectCourseImageFirst = '请先选择课表图片';
  static const invalidOcrResponse = '图片没有识别出内容，请换一张更清楚的课表截图。';
  static const invalidOcrCourseDataResponse = '识别到的课程不完整，请重拍后再试。';
  static const enterEightDigitPickupCode = '请输入8位取件码';
  static String pickupCodeFetchFailed(int statusCode) =>
      '没有取到课表，请核对 8 位取件码后重试。';
  static const invalidPickupCourseDataResponse = '取回的课表不完整，请确认取件码无误后重试。';
  static const invalidVersionCheckResponse = '暂时查不到新版本，不影响正常使用。';
  static const invalidQuestionAnalysisResponse = '这道题没有解析出结果，请换个说法再试。';
  static String backendRequestFailed(int statusCode) =>
      '网络没有连上，换个网络或稍后再试。';
  static const invalidBackendResponse = '服务暂时没有响应，请稍后重试。';
  static const backendRequestFailedFallback = '没能连上服务，请稍后重试。';
  static const invalidUserProfileResponse = '没能读到账号信息，请重新打开这一页。';
  static const courseJsonMustBeArray = '这份课表内容无法识别，请换一份文件再试。';
  static String courseJsonItemNotObject(int index) => '第 $index 门课程读不出来，请检查后重新导入。';
  static String courseJsonItemIncomplete(int index) => '第 $index 门课程缺少上课时间或地点，请补齐后重新导入。';
  static const lessonTimesImportedForSchool = '已按当前学校作息自动导入，可继续手动调整。';
  static const lessonTimesSchoolFailed = '没能读到学校作息，已保留你原来的设置。';
  static const lessonTimesNoSchool = '未选择学校，可导入通用作息后再调整。';
  static const lessonTimesGeneralFailed = '没能读到通用作息，可以手动填写每节课的开始时间。';
  static const addCourse = '添加课程';
  static const editCourse = '修改课程';
  static const courseNameHint = '课程名称';
  static String weekPickerText(int week) => '第 $week 周';
  static const to = '至';
  static String lessonPickerText(int lesson) => '第 $lesson 节';
  static const courseLocationHint = '课程地点';
  static const save = '保存';
  static const enterCourseName = '请输入课程名称';
  static const startWeekAfterEndWeek = '起始周不能大于结束周';
  static const startLessonAfterEndLesson = '起始节次不能晚于结束节次';
  static const aboutTitle = '关于';
  static const appDescription = '一个用于查看、导入、维护本学期课程安排的本地课表应用。';
  static const authorLabel = '作者';
  static const licenseLabel = '开源协议';
  static const gplLicense = 'GPL 许可证';
  static const authorQqLabel = '作者QQ';
  static const groupQqLabel = '交流QQ群';
  static const repositoryLabel = '开源仓库';
  static const loading = '读取中';
  static const checking = '检查中';
  static const unknown = '未知';
  static const versionInfo = '版本信息';
  static const currentVersion = '当前版本';
  static const latestVersion = '最新版本';
  static String checkFailed(Object error) => '检查失败：$error';
  static const checkUpdate = '检查更新';
  static const manualUpdate = '手动更新';
  static const checkingLatestVersion = '正在检查最新版本';
  static const noLatestVersion = '尚未获取最新版本';
  static const currentVersionTooLow = '当前版本低于最低可用版本，需要更新';
  static const newVersionAvailable = '发现新版本，可手动更新';
  static const alreadyLatestVersion = '当前已是最新版本';
  static const academicImportInitialStatus = '请在页面中登录教务系统';
  static const academicImportLoadFailed = '页面加载失败，请检查网络后重试';
  static String academicImportTitle(String schoolName) => '$schoolName 教务导入';
  static const academicImportLoginDetected = '检测到登录成功，正在提交后端导入';
  static const academicImportMissingCookie = '未读取到登录 Cookie，请重新登录';
  static String academicImportFailed(Object error) => '导入失败：$error';
  static const appSettingsTitle = '应用设置';
  static const termFirstDayLabel = '第一周第一天';
  static const notSet = '未设置';
  static const lessonTimesLabel = '每节课时间';
  static const notConfigured = '未配置';
  static const configured = '已配置';
  static const configure = '配置';
  static const maxWeeksLabel = '最大周数';
  static const resetSettingsLabel = '重置设置';
  static const confirmReset = '确认重置';
  static const termAndLessonTimesTitle = '学期与节次时间';
  static const termAndLessonTimesSubtitle =
      '第一周第一天用于计算当前周数；每节课开始时间用于桌面小组件匹配下一节课。';
  static const invalidMaxWeeks = '请输入正确的最大周数';
  static const syncCoursesTitle = '同步课程';
  static const syncCoursesMessage =
      '是否将新的总周数应用到所有持续整个学期的课程？\n所有持续时长超出新总周数的课程的持续时长将会被截短。';
  static const cancel = '取消';
  static const ok = '好的';
  static const resetSchoolSelectionTitle = '重置学校选择';
  static const resetSchoolSelectionMessage = '确认重新选择学校吗？本地已保存的课程将被删除。';
  static const confirm = '确认';
  static const resetSettingsMessage = '确认重置设置吗？本地已保存的课程将被删除。';
  static const settingsReset = '设置已重置';
  static const schoolInfo = '学校信息';
  static const reselectSchool = '重选学校';
  static const noSchoolSelected = '未选择学校';
  static const otherImportMethods = '其他方式导入';
  static const accountTitle = '账号';
  static const loggedIn = '已登录';
  static String requestFailed(Object error) => '请求失败：$error';
  static const loggedOut = '已退出登录';
  static String logoutFailed(Object error) => '退出登录失败：$error';
  static const loginForChaoxing = '登录后可使用学习通作业辅助';
  static const loginOptionalDescription = '课表、桌面小组件等功能仍可不登录使用。';
  static const emailLogin = '邮箱登录';
  static const loginCode = '登录码';
  static const register = '注册';
  static const username = '用户名';
  static const qqEmail = 'QQ 邮箱';
  static const password = '密码';
  static const registerAndLogin = '注册并登录';
  static const login = '登录';
  static const fieldRequired = '不能为空';
  static const enterQqEmail = '请输入 QQ 邮箱';
  static const useQqEmail = '请使用 QQ 邮箱';
  static const emailStatus = '邮箱状态';
  static const verified = '已认定';
  static const unverified = '未认定';
  static const questionAnalysisCount = '做题辅助次数';
  static const loginCodeCopied = '登录码已复制';
  static const copyLoginCode = '复制登录码';
  static const logout = '退出登录';
  static const courseSettingsTitle = '课程设置';
  static const importCourses = '导入课程';
  static const batchAdd = '批量添加';
  static const batchDelete = '批量删除';
  static const chooseImportFromTopRight = '点击右上角选择导入课程';
  static const deleteCourseTitle = '删除课程';
  static String deleteCourseMessage(String name) => '确定要删除“$name”吗？此操作不可撤销。';
  static const delete = '删除';
  static String courseDeleted(String name) => '已成功删除课程：$name';
  static const deleteCoursesTitle = '删除多门课程';
  static String deleteCoursesMessage(String names) => '确定删除以下课程吗？\n\n$names';
  static const confirmDelete = '确定删除';
  static String coursesAdded(int count) => '成功添加 $count 门课程';
  static const schoolImportRequiresSupportedSchool = '需先选择支持教务系统导入的学校';
  static const importByOcr = '用图片导入';
  static const importByOcrSubtitle = '识别课表图片后导入课程';
  static const importByPickupCode = '使用取件码导入';
  static const importByPickupCodeSubtitle = '输入取件码获取课程数据';
  static const importByAcademic = '教务系统导入';
  static const recognizingCourseImage = '正在上传图片并识别，请稍候';
  static const noCoursesRecognized = '未识别到课程';
  static String coursesImported(int count) => '成功导入 $count 门课程';
  static String ocrImportFailed(Object error) => '图片没有识别成功，请换一张更清楚的课表截图再试。';
  static const recognitionCompleted = '识别完成';
  static String pickupCodeLabel(String code) => '取件码：$code';
  static const copyPickupCode = '复制取件码';
  static const continueImport = '继续导入';
  static const fetchingCourses = '正在获取课程，请稍候';
  static const pickupCodeNoCourses = '取件码没有对应课程';
  static String pickupCodeImportFailed(Object error) => '取件码导入失败：$error';
  static const selectSchoolFirst = '请先选择学校';
  static String schoolConfigLoadFailed(Object error) => '学校配置加载失败：$error';
  static const academicImportNotConfigured = '当前学校未配置教务系统导入方法';
  static const selectFirstWeekFirstDayTitle = '选择第一周第一天';
  static const importTermSetupSubtitle =
      '课程导入完成后，请先设置学期开始日期；下方节次时间通过上下滑动选择，也可以暂不配置。';
  static const continueImportAction = '继续导入';
  static const cancelImport = '取消导入';
  static const edit = '编辑';
  static const color = '颜色';
  static const weekRangeLabel = '起止周';
  static const classTimeLabel = '上课时间';
  static const courseLocationLabel = '课程地点';
  static const selectAll = '全选';
  static const batchAddCoursesTitle = '批量添加课程';
  static const courseJsonHint = '粘贴课程文本';
  static const help = '使用说明';
  static const exportJson = '导出课程';
  static const copiedToClipboard = '已复制到剪贴板';
  static const batchAddHelpTitle = '批量添加说明';
  static const batchAddHelpExample =
      '[\n'
      '  {\n'
      '    "name": "高等数学",\n'
      '    "startWeek": 1,\n'
      '    "endWeek": 18,\n'
      '    "dayOfWeek": 1,\n'
      '    "startLesson": 1,\n'
      '    "endLesson": 2,\n'
      '    "location": "A101"\n'
      '  }\n'
      ']';
  static const invalidJsonInput = '这段内容的格式对不上，请检查后再试。';
  static String selectColorForCourse(String name) => '选择颜色：$name';
  static const setCourseColor = '设置课程颜色';
  static String selectedCourseLabel(String name) => '当前：$name';
  static const confirmImport = '确认导入';
  static const enterPickupCodeTitle = '输入取件码';
  static const pickupCodeHint = '例如 A7K9Q2TX';
  static const import = '导入';
  static String homeWeekLabel(int week) => '第$week 周';
  static String homeLessonRangeLabel(int startLesson, int endLesson) =>
      '第$startLesson-$endLesson 节';
  static const setupFirstWeekFirstDayTitle = '设置第一周第一天';
  static const setupFirstWeekFirstDaySubtitle =
      '设置后即可自动计算当前周数；节次时间可选填，用于桌面小组件判断下一节课。';
  static const saveSettings = '保存设置';
  static const setupLater = '稍后设置';
  static const later = '稍后再说';
  static const updateNow = '去更新';
  static const homeTab = '首页';
  static const scheduleTab = '课程表';
  static const mineTab = '我的';
  static const noCoursesToday = '今天没有课，可以休息一下';
  static const coursesFinishedToday = '今天的课已经上完了';
  static const courseCount = '课程总数';
  static const currentWeekLabel = '本周';
  static const todayCourses = '今日课程';
  static const viewSchedule = '查看课表';
  static const homeHeroTitle = '今天也要稳稳上课';
  static String homeHeroSubtitle(String weekText, int count) =>
      '$weekText · 今日待上 $count 节课';
  static const openSchedule = '打开课表';
  static const thisWeekCourses = '本周课程';
  static const loginOrRegister = '登录/注册';
  static const homeWidgetTitle = '桌面小组件';
  static const homeWidgetSubtitle = '查看不同系统的添加方式';
  static const chaoxingHomeworkTitle = '学习通作业辅助';
  static const chaoxingHomeworkSubtitle = '需登录后使用自动化处理作业流程';
  static const courseSettingsSubtitle = '导入、编辑和导出课程';
  static const appSettingsSubtitle = '提醒时间、节次和偏好设置';
  static const aboutSubtitle = '版本信息与项目说明';
  static const addWidgetTitle = '添加小组件';
  static const addWidgetManualMessage = '不同系统添加小组件方式不同，请前往用户手册查看符合你系统的添加方式。';
  static const close = '关闭';
  static const openWebsite = '前往官网';
  static const chaoxingLoginRequiredFromHome = '请先登录后再使用学习通作业辅助';
  static const goLogin = '去登录';
  static const mineSpace = '我的空间';
  static String mineUsage(String name, int count) => '$name，已使用 $count 次做题辅助';
  static const mineGuestSubtitle = '课程、提醒和工具都在这里';
  static String monthText(int month) => '$month月';
  static const locationNotSet = '未设置地点';
  static const chooseSchoolTitle = '选择学校';
  static const chooseSchoolSubtitle = '请选择当前使用的教务系统，学校列表由后端实时提供。';
  static const searchSchoolHint = '搜索学校';
  static const clearSearch = '清空搜索';
  static String schoolListLoadFailed(Object error) => '学校列表加载失败：$error';
  static const noSchoolsFromBackend = '后端未返回可用学校';
  static const enterCourseImport = '进入课程导入';
  static const useOtherImportMethods = '使用其他方式导入';
  static const noMatchedSchool = '未找到匹配学校';
  static const academicImportConfigured = '已配置教务系统导入';
  static const academicImportNotYetConfigured = '暂未配置教务系统导入';
  static const setupTermAndLessonTimeTitle = '设置学期与上课时间';
  static const setupTermAndLessonTimeSubtitle = '先选择第一周第一天，再按需配置每节课开始时间';
  static const saveConfig = '保存配置';
  static const timeConfigTitle = '时间配置';
  static const select = '选择';
  static const lessonStartTimesLabel = '每节课开始时间';
  static const lessonStartTimesHelp =
      '可留空。导入作息只会帮你填入数据，保存前仍可逐节修改；留空时课程表正常显示，但桌面小组件不会显示上课时间，也无法按当前时间判断下一节课。';
  static String lessonNumberWithSpaces(int lesson) => '第 $lesson 节';
  static String selectLessonStartTime(int lesson) => '第 $lesson 节开始时间';
  static const morning = '上午';
  static const afternoon = '下午';
  static const period = '时段';
  static const hour = '小时';
  static const minute = '分钟';
  static const importGeneralLessonTimes = '导入通用作息';
  static String importLessonTimesForStart(String start) => '导入 $start 上课作息';
  static const generalLessonTimesImported = '已导入通用作息，可继续逐节修改';
  static String lessonTimesImportedForStart(String start) =>
      '已导入$start上课作息，可继续逐节修改';
  static const generalLessonTimesDescription = '这套为通用配置';
  static String lessonTimesDescription(String start) => '这套为$start上课';

  static const weekLabels = <String>['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  static const remindWays = <String>['日历日程', '闹钟', '通知'];
  static const alarmWays = <String>['需要确认', '直接设置'];
  static String localDateLabel(DateTime date) =>
      '${date.year}年${date.month}月${date.day}日';
  static String weekRangeText(int startWeek, int endWeek) =>
      '$startWeek-$endWeek周';
  static String weekListText(String weeks) => '$weeks周';

  /// 单双周标记后缀，用于 WeekPattern.text。
  static const weekRuleOddSuffix = '(单)';
  static const weekRuleEvenSuffix = '(双)';

  /// 导入结果提示：有新增或更新。
  static String importSummary({
    required int added,
    required int updated,
    required int skipped,
  }) {
    final parts = <String>[];
    if (added > 0) parts.add('新增 $added');
    if (updated > 0) parts.add('更新 $updated');
    if (skipped > 0) parts.add('未变化 $skipped');
    return '导入完成：${parts.join('，')}';
  }

  /// 导入结果提示：与现有课表完全一致。
  static String importUnchanged(int skipped) =>
      skipped > 0 ? '课表没有变化（$skipped 门课程已存在）' : '没有可导入的课程';

  static const widgetFinishedMessages = <String>[
    '今天的课已经上完了',
    '今日课程已全部结束',
    '今天没有下一节课啦',
    '今日课表已完成',
    '今天课程收工了',
  ];
  static const widgetSyncFailed = '数据同步失败';
  static const widgetNoCoursesToday = '今天没有课';
  static const widgetTimeNotConfigured = '时间未配置';
  static const widgetStarted = '已开始';
  static String widgetRemaining(String duration) => '剩余 $duration';
  static const unnamedCourse = '未命名课程';
  static const roomNotFilled = '教室未填写';
  static const fullWeekdays = <int, String>{
    DateTime.monday: '星期一',
    DateTime.tuesday: '星期二',
    DateTime.wednesday: '星期三',
    DateTime.thursday: '星期四',
    DateTime.friday: '星期五',
    DateTime.saturday: '星期六',
    DateTime.sunday: '星期日',
  };
  static String todayWithWeekday(DateTime date) =>
      '今天 / ${fullWeekdays[date.weekday] ?? ''}';
  static String weekNumber(int week) => '第$week周';
  static String lessonText(int lesson) => '第$lesson节';
  static String lessonRangeText(int startLesson, int endLesson) =>
      '第$startLesson-$endLesson节';
  static String minutes(int value) => '$value分钟';
  static String hours(int value) => '$value小时';
  static String hoursMinutes(int hours, int minutes) => '$hours小时$minutes分钟';

  static const chaoxingTitle = '学习通作业辅助';
  static const chaoxingHomeTitle = '学习通';
  static const chaoxingInitialStatus = '请先登录学习通，并手动进入作业题目页面。';
  static const chaoxingPageLoading = '页面加载中';
  static const chaoxingEnterHomeworkPage = '请进入作业页面后点击开始答题';
  static String chaoxingPageLoadFailed(String error) => '页面加载失败：$error';
  static const chaoxingReload = '重新加载';
  static const chaoxingBackHome = '回到学习通首页';
  static const chaoxingLoginRequired = '请先登录后再使用做题辅助';
  static const chaoxingReadingPage = '正在读取当前页面';
  static const chaoxingNoQuestions = '当前页面未识别到题目';
  static String chaoxingFoundQuestions(int count) => '共找到 $count 道题';
  static String chaoxingProcessingQuestion(String number) => '正在处理第 $number 题';
  static String chaoxingNoAnswer(String number) => '第 $number 题未提取到答案';
  static String chaoxingQuestionSkipped(String number) => '第 $number 题已作答，已跳过';
  static String chaoxingQuestionTimeout(String number) => '第 $number 题处理超时';
  static const chaoxingLoginInvalid = '登录状态无效，请重新登录后再使用';
  static String chaoxingQuestionFailed(String number) => '第 $number 题处理失败';
  static String chaoxingStopped(int success, int failed) =>
      '已停止，成功 $success 题，失败 $failed 题';
  static String chaoxingCompleted(int success, int failed) =>
      '答题完成，成功 $success 题，失败 $failed 题';
  static String chaoxingAutomationError(Object error) => '自动化异常：$error';
  static const chaoxingStopping = '正在停止，当前题处理完后结束';
  static String chaoxingCollapsedProgress(int current, int total) =>
      '答题中 $current/$total';
  static const chaoxingCollapsedIdle = '作业辅助';
  static const chaoxingPanelTitle = '做题辅助面板';
  static const chaoxingCollapsePanel = '收起';
  static const chaoxingPageTitleLabel = '页面';
  static const chaoxingUrlLabel = '地址';
  static const chaoxingFoundMetric = '题目';
  static const chaoxingCurrentMetric = '当前';
  static const chaoxingSuccessMetric = '成功';
  static const chaoxingFailedMetric = '失败';
  static const chaoxingStart = '开始答题';
  static const chaoxingStop = '停止';
  static const chaoxingAnswerKey = '答案';
  /// 注入脚本已移至 `chaoxing_scripts.dart`，这里转发以保持调用方式不变。
  static const chaoxingCollectQuestionsJs = ChaoxingScripts.chaoxingCollectQuestionsJs;
  static const chaoxingAnswerJs = ChaoxingScripts.chaoxingAnswerJs;
}
