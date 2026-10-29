/// 全站文案。
///
/// 写法约定（与网页端一致，改文案时请一并遵守）：
/// - 按钮用「动词 + 对象」：保存更改、删除课程、导入课表；不写「确认」「提交」；
/// - 报错说清发生了什么、用户能做什么；
/// - 空状态说明为什么空、下一步做什么；
/// - 不出现技术术语（接口、参数、状态码、令牌、缓存……），
///   也不写「努力加载中」这类空话，不用感叹号和表情符号。
class AppStrings {
  const AppStrings._();

  // ==================== 身份与账号 ====================
  static const appName = '珂拉课程表';
  static const appSlogan = '把一学期的课收进一张表';
  static const notLoggedIn = '未登录';
  static const notGenerated = '未生成';
  static const unknown = '未知';
  static const loading = '正在读取';
  static const checking = '正在检查';

  static const accountTitle = '账号';
  static const loggedIn = '已登录';
  static const loggedOut = '已退出登录';
  static const requestFailed = '没有连上服务，换个网络或稍后再试。';
  static const logoutFailed = '退出没有成功，稍后再试一次。';

  static const emailLogin = '账号密码';
  static const loginCode = '登录码';
  static const register = '注册账号';
  static const username = '用户名';
  static const qqEmail = 'QQ 邮箱';
  static const password = '密码';
  static const login = '登录';
  static const registerAndLogin = '注册并登录';
  static const fieldRequired = '这一项要填上。';
  static const enterQqEmail = '请填写 QQ 邮箱，例如 123456789@qq.com。';
  static const useQqEmail = 'QQ 邮箱';
  static const emailStatus = '邮箱状态';
  static const verified = '已验证';
  static const unverified = '待验证';
  static const questionAnalysisCount = '已解析题目';
  static const loginCodeCopied = '登录码已复制';
  static const copyLoginCode = '复制登录码';
  static const logout = '退出登录';
  static const logoutAllDevices = '退出所有设备';
  static const logoutAllHint = '其它设备下次打开时会要求重新登录，这台不受影响。';

  static const emailVerifiedNotice = '邮箱已验证，导入和识别都可以用。';
  static const emailUnverifiedNotice = '验证邮箱之后，教务导入、截图识别和题目解析才会开放。';
  static const sendVerifyMail = '发送验证邮件';
  static const verifyMailSent = '验证邮件已经发出，请查收邮箱。';
  static const verifyEmailTitle = '验证邮箱';
  static const verifyEmailAction = '验证这个邮箱';

  // ==================== 首页 ====================
  static const homeTab = '首页';
  static const scheduleTab = '课表';
  static const mineTab = '我的';
  static const importTab = '导入';
  static const practiceTab = '题目';
  static const todayCourses = '今天的课';
  static const courseCount = '课程总数';
  static const currentWeekLabel = '当前周次';
  static const viewSchedule = '查看课表';
  static const openSchedule = '打开我的课表';
  static const noCoursesToday = '今天没有课，可以安排自习，或者把作业提前写完。';
  static const noCoursesYet = '课表还是空的。先把这学期的课导进来，之后每天打开就能看到今天上什么。';
  static const coursesFinishedToday = '今天的课已经上完了。';

  static const homeHeroTitle = '今天上什么';
  static String homeHeroSubtitle(String week, int count) =>
      '$week · 今天 $count 节课';
  static String homeWeekLabel(int week) => '第 $week 周';
  static String homeLessonRangeLabel(int start, int end) =>
      start == end ? '第 $start 节' : '第 $start-$end 节';

  // ==================== 课表 ====================
  static const weekLabels = ['一', '二', '三', '四', '五', '六', '日'];
  static const fullWeekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  static const thisWeekCourses = '本周课程';
  static String monthText(int month) => '$month 月';
  static String todayWithWeekday(String weekday, String date) =>
      '今天 · $weekday $date';

  /// 小组件顶栏：今天 + 星期 + 日期。
  static String todayWithWeekdayDate(DateTime date) {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final weekday = weekdays[(date.weekday - 1).clamp(0, 6)];
    return '今天 · $weekday · ${date.month} 月 ${date.day} 日';
  }

  /// 课程总数的一句话。
  static String totalCourses(int count) =>
      count == 0 ? '还没有课程' : '一共 $count 门课';
  static String weekNumber(int week) => '第 $week 周';
  static const locationNotSet = '地点没有填';
  static const roomNotFilled = '地点没有填';
  static const emptyScheduleTitle = '课表还是空的';
  static const emptyScheduleCopy = '从教务系统导入、识别一张课表截图，或者手动加一门，三种方式任选一种。';
  static const emptyScheduleImport = '去导入课表';
  static const emptyScheduleAddManually = '手动加一门课';
  static const addCourse = '添加课程';
  static const editCourse = '修改课程';
  static const batchAdd = '批量添加';
  static const batchDelete = '批量删除';
  static const deleteCourseTitle = '删除这门课？';
  static const delete = '删除';
  static const deleteCoursesTitle = '删除选中的课？';
  static const confirmDelete = '确认并删除';
  static String deleteCourseMessage(String name) =>
      '删除后「$name」会从每周的课表里消失，这一步无法撤销。';
  static String deleteCoursesMessage(int count) =>
      '删除后这 $count 门课会从每周的课表里消失，这一步无法撤销。';
  static const courseDeleted = '课程已删除';
  static const coursesDeleted = '课程已删除';
  static const courseNameHint = '课程名称';
  static const courseLocationHint = '课程地点';
  static const enterCourseName = '请填写课程名称。';
  static const startWeekAfterEndWeek = '起始周不能晚于结束周。';
  static const startLessonAfterEndLesson = '起始节次不能晚于结束节次。';
  static String weekPickerText(int week) => '第 $week 周';
  static String lessonPickerText(int lesson) => '第 $lesson 节';
  static String weekRangeText(int start, int end) =>
      start == end ? '第 $start 周' : '第 $start-$end 周';
  static String weekListText(List<int> weeks) {
    if (weeks.isEmpty) {
      return '还没有设置周次';
    }
    return '第 ${weeks.first}-${weeks.last} 周';
  }

  static String lessonRangeText(int start, int end) =>
      start == end ? '第 $start 节' : '第 $start-$end 节';
  static String lessonText(int lesson) => '第 $lesson 节';
  static const weekRuleOddSuffix = '单周';
  static const weekRuleEvenSuffix = '双周';

  // ==================== 导入 ====================
  static const importTitle = '导入课表';
  static const importSubtitle = '三种方式把课表带进来，哪种顺手用哪种。';
  static const academicImportTitle = '教务导入';
  static const academicImportSubtitle = '在应用里登录学校教务系统，一次取回整学期的课。';
  static const importByOcr = '截图识别';
  static const importByOcrSubtitle = '上传课表截图，读出课程、节次和地点。';
  static const importByPickupCode = '取件码';
  static const importByPickupCodeSubtitle = '输入 8 位取件码，取回之前保存或别人分享的课表。';
  static const importByAcademic = '教务导入';

  static const selectCourseImageFirst = '先选一张课表截图。';
  static const invalidOcrResponse = '图片没有识别出内容，换一张更清楚的课表截图再试。';
  static const invalidOcrCourseDataResponse = '识别出的课程不完整，换一张图再试一次。';
  static const recognizingCourseImage = '正在识别截图…';
  static const recognitionCompleted = '识别完成，记得先核对再保存。';
  static const noCoursesRecognized = '识别完成，但没有读出课程。换一张格子边框完整的截图再试。';
  static const coursesImported = '课程已保存到课表';
  static const ocrImportFailed = '这次没有识别出来，换一张图再试一次。';
  static const pickupCodeLabel = '取件码';
  static const copyPickupCode = '复制取件码';
  static const pickupCodeCopied = '取件码已复制';
  static const enterEightDigitPickupCode = '取件码是 8 位，请对照发码的人给你的内容填写。';
  static const fetchingCourses = '正在取回课表…';
  static const pickupCodeNoCourses = '这个取件码里没有课程。可能这份内容是空的，请让对方重新生成一次。';
  static const pickupCodeImportFailed = '没有取回课表，核对取件码后再试一次。';
  static const enterPickupCodeTitle = '输入取件码';
  static const pickupCodeHint = '8 位，字母不区分大小写';
  static const importByPickupCodeTitle = '用取件码取回';

  static const selectSchoolFirst = '先选择你的学校。';
  static const chooseSchoolTitle = '选择学校';
  static const chooseSchoolSubtitle = '选好学校后，在应用里登录一次教务系统，就能取回整学期课表。';
  static const searchSchoolHint = '搜索学校名称';
  static const clearSearch = '清除搜索';
  static const schoolListLoadFailed = '没能读到学校列表，稍后再打开这一页试试。';
  static const noSchoolsFromBackend = '现在还没有可以导入的学校，先用截图识别或者手动添加。';
  static const noMatchedSchool = '没有匹配的学校，换个关键词试试。';
  static const academicImportNotYetConfigured = '这所学校还没有接通，可以改用截图识别。';
  static const academicImportConfigured = '已接通，可以登录导入';
  static const academicImportInitialStatus = '请在页面里登录教务系统';
  static const academicImportLoadFailed = '学校页面没有打开成功，看看网络是否正常，或者稍后再试一次。';
  static String academicImportTitleWithSchool(String schoolName) =>
      '$schoolName · 教务导入';
  static const academicImportLoginDetected = '登录成功，正在把课表读进来';
  static const academicImportMissingCookie = '这次没有读到你的登录状态，请重新登录学校页面。';
  static const academicImportFailed = '课表没有导入成功，稍后再试一次。';
  static const selectFirstWeekFirstDayTitle = '设置开学第一周的第一天';
  static const importTermSetupSubtitle = '有了这个日期，课表才知道今天是第几周。';
  static const continueImportAction = '继续导入';
  static const cancelImport = '取消导入';
  static const importSummary = '已导入到课表';
  static const importUnchanged = '课表没有变化';

  // ==================== 识别与解析 ====================
  static const uploadImagesTitle = '把课表截图放进来';
  static const uploadImagesHint = '一次最多 9 张。截整张课表、格子边框完整的时候识别最准。';
  static const chooseImages = '选择图片';
  static const clearSelected = '清空已选';
  static const startRecognition = '开始识别';
  static const recognizedCourses = '识别出的课程';
  static const saveToSchedule = '保存到我的课表';
  static const noImageChosen = '还没有选择图片。';

  static const questionsTitle = '题目解析';
  static const questionsSubtitle = '把做不出来的题贴进来，看它怎么解、错在哪一步。';
  static const choiceQuestion = '选择题';
  static const openQuestion = '填空与主观题';
  static const questionContentLabel = '题目内容';
  static const questionContentHint = '连同题干和已知条件一起贴进来，公式用文字写也没关系。';
  static const questionOptionsLabel = '选项';
  static const addOption = '再加一个选项';
  static const dropOption = '去掉最后一个';
  static const questionMaterialLabel = '材料或背景';
  static const questionMaterialHint = '选填。阅读题、案例分析可以放这里。';
  static const questionReferenceLabel = '参考答案';
  static const questionReferenceHint = '选填。想让它对照标准答案讲解时填。';
  static const questionMineLabel = '我的答案';
  static const questionMineHint = '选填。填了会指出错在哪一步。';
  static const startAnalysis = '开始解析';
  static const analyzing = '正在解析…';
  static const clearAndRewrite = '清空重写';
  static const analysisResult = '解析结果';
  static const answerLabel = '答案';
  static const analysisLabel = '解题思路';
  static const invalidQuestionAnalysisResponse = '这道题没有解析出结果，换个说法再试。';
  static const analysisEmptyNotice = '这次没有拿到可以逐句阅读的解析。把题目和选项分成几行再试一次。';

  // ==================== 设置 ====================
  static const appSettingsTitle = '设置';
  static const appSettingsSubtitle = '学期、作息、提醒';
  static const courseSettingsTitle = '课程管理';
  static const courseSettingsSubtitle = '增删课程、调整周次与节次';
  static const aboutTitle = '关于';
  static const aboutSubtitle = '版本、作者与开源信息';
  static const termFirstDayLabel = '开学第一天';
  static const notSet = '未设置';
  static const lessonTimesLabel = '上课时间';
  static const notConfigured = '还没有配置';
  static const configured = '已配置';
  static const maxWeeksLabel = '总周数';
  static const resetSettingsLabel = '恢复默认设置';
  static const confirmReset = '确认恢复';
  static const termAndLessonTimesTitle = '学期与作息';
  static const termAndLessonTimesSubtitle = '这里决定课表按哪一天算第一周、每节课几点开始。';
  static const invalidMaxWeeks = '总周数要在 1 到 30 之间。';
  static const syncCoursesTitle = '同步课表';
  static const syncCoursesMessage = '把这份课表保存到账号里？保存后换设备登录也能看到。';
  static const cancel = '取消';
  static const ok = '知道了';
  static const save = '保存';
  static const saveSettings = '保存设置';
  static const saveChanges = '保存更改';
  static const close = '关闭';
  static const confirm = '确定';
  static const resetSchoolSelectionTitle = '更换学校？';
  static const resetSchoolSelectionMessage = '更换学校后，导入方式会按新学校重新设置。已经导入的课表不会丢。';
  static const resetSettingsMessage = '恢复默认会清掉开学日期、上课时间和提醒设置。课表本身不受影响。';
  static const settingsReset = '设置已恢复默认';
  static const schoolInfo = '学校';
  static const reselectSchool = '更换学校';
  static const noSchoolSelected = '还没有选择学校';
  static const otherImportMethods = '其它导入方式';
  static const singleChoice = '单选题';

  static const timeConfigTitle = '上课时间';
  static const selectLessonStartTime = '选择上课时间';
  static const lessonStartTimesLabel = '每节课的开始时间';
  static const lessonStartTimesHelp = '按学校作息填，后面算「第几节课几点上」都靠这里。';
  static String lessonNumberWithSpaces(int lesson) => '第 $lesson 节';
  static const morning = '上午';
  static const afternoon = '下午';
  static const period = '节';
  static const hour = '时';
  static const minute = '分';
  static const importGeneralLessonTimes = '导入通用作息';
  static String importLessonTimesForStart(String time) => '$time 开始';
  static const generalLessonTimesImported = '通用作息已导入，可以逐节微调。';
  static String lessonTimesImportedForStart(String time) => '已按 $time 开始导入';
  static const lessonTimesDescription = '每节课的开始时间决定课表上显示的上课时刻。';
  static const generalLessonTimesDescription = '通用的上课时间，学校有单独作息时以学校为准。';
  static const lessonTimesImportedForSchool = '已按当前学校作息自动导入，可以继续手动调整。';
  static const lessonTimesSchoolFailed = '没能读到学校作息，保留了你原来的设置。';
  static const lessonTimesNoSchool = '还没有选择学校，可以先导入通用作息再调整。';
  static const lessonTimesGeneralFailed = '没能读到通用作息，可以手动填每节课的开始时间。';

  static const remindWays = ['不提醒', '提前 5 分钟', '提前 10 分钟', '提前 15 分钟'];
  static const alarmWays = ['不响铃', '响铃一次', '响铃两次'];
  static const versionInfo = '版本信息';
  static const currentVersion = '当前版本';
  static const latestVersion = '最新版本';
  static const checkUpdate = '检查更新';
  static const manualUpdate = '手动更新';
  static const checkingLatestVersion = '正在检查最新版本';
  static const noLatestVersion = '还没有取到最新版本';
  static const currentVersionTooLow = '这个版本太旧，已经不能继续用，请更新到新版本。';
  static const newVersionAvailable = '有新版本可以更新';
  static const alreadyLatestVersion = '当前已是最新版本';
  static const updateAvailableTitle = '有新版本';
  static const later = '以后再说';
  static const updateNow = '现在更新';
  static const invalidVersionCheckResponse = '暂时查不到新版本，不影响正常使用。';
  static String checkFailed(Object error) => '没能检查更新。看看网络是否正常，稍后再试一次。';
  static const appDescription = '把一学期的课收进一张表：看今天上什么，也能从教务系统或截图导进来。';
  static const authorLabel = '作者';
  static const licenseLabel = '开源协议';
  static const gplLicense = 'GPL 许可证';
  static const authorQqLabel = '作者 QQ';
  static const groupQqLabel = '交流 QQ 群';
  static const repositoryLabel = '开源仓库';

  // ==================== 通用错误 ====================
  static const invalidSchoolsResponse = '没能读到学校列表，稍后再打开这一页。';
  static const invalidSchoolConfigResponse = '没能读到这所学校的作息，换一所学校或稍后再试。';
  static const invalidSchoolLessonTimesResponse = '没能读到上课时间，稍后再试。';
  static const invalidGeneralLessonTimesResponse = '没能读到上课时间，可以手动填每节课的开始时间。';
  static const invalidCourseImportResponse = '课表没有导入成功，稍后再试一次。';
  static const invalidCourseDataResponse = '课表读取不完整，重新打开这一页试试。';
  static const invalidPickupCourseDataResponse = '取回的课表不完整，确认取件码无误后重试。';
  static const invalidBackendResponse = '服务暂时没有响应，稍后再试。';
  static const invalidUserProfileResponse = '没能读到账号信息，重新打开这一页试试。';
  static const backendRequestFailedFallback = '没能连上服务，稍后再试。';
  static const networkOffline = '现在没有网络。连上网络后再试。';
  static const serverBusy = '服务有点忙，稍等一下再试。';
  static const quotaExhausted = '今天的次数用完了，明天会自动恢复。';
  static const needLogin = '这一步要先登录。';
  static const forbidden = '这个操作需要管理员权限。';
  static const courseJsonMustBeArray = '这份课表内容认不出来，换一份再试。';
  static String courseJsonItemNotObject(int index) =>
      '第 $index 门课程读不出来，检查后重新导入。';
  static String courseJsonItemIncomplete(int index) =>
      '第 $index 门课程缺少上课时间或地点，补齐后重新导入。';
  static String backendRequestFailed(int statusCode) => '网络没有连上，换个网络或稍后再试。';

  // ==================== 桌面端 ====================
  static const desktopWindowTitle = '珂拉课程表';
  static const desktopSidebarSchedule = '我的课表';
  static const desktopSidebarImport = '导入课表';
  static const desktopSidebarQuestions = '题目解析';
  static const desktopSidebarSettings = '设置';
  static const desktopResizeHint = '把窗口拉窄，界面会自动切换成手机上的排版。';

  // ==================== 小组件 ====================
  static const homeWidgetTitle = '桌面小组件';
  static const homeWidgetSubtitle = '把今天的课放到手机桌面上';
  static const addWidgetTitle = '把小组件放到桌面';
  static const addWidgetManualMessage =
      '小组件需要你在手机桌面上手动添加：长按桌面空白处，选择「小组件」，找到珂拉课程表，挑一个尺寸放上去。小组件会跟着应用里的课表自动更新。';
  static const openWebsite = '打开官网';
  static String widgetRemaining(String duration) => '还有 $duration';
  static const widgetFinishedMessages = '今天的课已经上完了';
  static const widgetSyncFailed = '小组件同步没有成功，重新打开一次应用就会再试。';
  static const widgetNoCoursesToday = '今天没有课';
  static const widgetTimeNotConfigured = '还没有设置上课时间';
  static const widgetStarted = '正在上课';

  /// 只剩几分钟 / 几小时 / 几小时几分钟，三句都拼得出来。
  static String minutes(int value) => '$value 分钟';
  static String hours(int value) => '$value 小时';
  static String hoursMinutes(int hoursPart, int minutesPart) =>
      '$hoursPart 小时 $minutesPart 分钟';
  static String localDateLabel(DateTime date) =>
      '${date.month} 月 ${date.day} 日';

  // ==================== 本地导入（截图之外的手动通道）====================
  static const importCourses = '导入课表';
  static const noCoursesAdded = '还没有添加课程';
  static const coursesAdded = '课程已加进课表';
  static const help = '怎么填';
  static const exportJson = '导出课表';
  static const copiedToClipboard = '已复制';
  static const batchAddCoursesTitle = '一次贴进多门课';
  static const batchAddHelpTitle = '每行写一门课，用竖线分开';
  static const batchAddHelpExample =
      '课程名称|周一|第1-2节|A101|张三\n高等数学|周二|第3-4节|B204|李四';
  static const courseJsonHint = '课程名称|星期|节次|地点|老师';
  static const batchAddHelpDescription = '地点和老师可以留空，其余三项要写全。';
  static const invalidJsonInput = '这段内容读不出来，对照下面的格式再检查一遍。';
  static const selectColorForCourse = '选一个颜色';
  static const setCourseColor = '设置课程颜色';
  static const selectedCourseLabel = '已选';
  static const confirmImport = '确认导入';
  static const classTimeLabel = '上课时间';
  static const weekRangeLabel = '周次';
  static const color = '颜色';
  static const week = '星期';
  static const selectAll = '全选';
  static const unnamedCourse = '未命名课程';
  static const importByOcrFailed = '截图没有识别成功，换一张再试。';

  // ==================== 兼容保留（旧调用点仍在用）====================
  static const academicImportTitleLegacy = '教务导入';
  static const chooseSchoolTitleLegacy = '选择学校';
  static const setupTermAndLessonTimeTitle = '设置学期与作息';
  static const setupTermAndLessonTimeSubtitle = '第一次使用要先填两个日期，之后课表才知道现在是第几周。';
  static const setupFirstWeekFirstDayTitle = '开学第一周的第一天是哪天';
  static const setupFirstWeekFirstDaySubtitle = '填错也不要紧，随时可以在设置里改。';
  static const setupLater = '稍后再设';
  static const configure = '去设置';
  static const select = '选择';
  static const time = '时间';
  static const saveConfig = '保存配置';
}
