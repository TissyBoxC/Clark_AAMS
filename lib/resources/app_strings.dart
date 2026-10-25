class AppStrings {
  const AppStrings._();

  static const appName = '珂拉课程表';
  static const updateAvailableTitle = '发现新版本';
  static const notLoggedIn = '未登录';
  static const notGenerated = '未生成';
  static const unknownQuestionType = '未知题型';
  static const invalidSchoolsResponse = '学校列表响应格式错误';
  static const invalidSchoolConfigResponse = '学校配置响应格式错误';
  static const invalidSchoolLessonTimesResponse = '学校节次时间响应格式错误';
  static const invalidGeneralLessonTimesResponse = '通用节次时间响应格式错误';
  static const invalidCourseImportResponse = '课表导入响应格式错误';
  static const invalidCourseDataResponse = '课表数据响应格式错误';
  static const selectCourseImageFirst = '请先选择课表图片';
  static const invalidOcrResponse = 'OCR响应格式错误';
  static const invalidOcrCourseDataResponse = 'OCR课程数据响应格式错误';
  static const enterEightDigitPickupCode = '请输入8位取件码';
  static String pickupCodeFetchFailed(int statusCode) =>
      '取件码获取失败：HTTP $statusCode';
  static const invalidPickupCourseDataResponse = '取件码课程数据格式错误';
  static const invalidVersionCheckResponse = '版本检查响应格式错误';
  static const invalidQuestionAnalysisResponse = '题目解析响应格式错误';
  static String backendRequestFailed(int statusCode) =>
      '后端请求失败：HTTP $statusCode';
  static const invalidBackendResponse = '后端响应格式错误';
  static const backendRequestFailedFallback = '后端请求失败';
  static const invalidUserProfileResponse = '用户资料响应格式错误';
  static const courseJsonMustBeArray = '课程 JSON 必须是数组';
  static String courseJsonItemNotObject(int index) => '第 $index 门课程不是对象';
  static String courseJsonItemIncomplete(int index) => '第 $index 门课程字段不完整';
  static const lessonTimesImportedForSchool = '已按当前学校作息自动导入，可继续手动调整。';
  static const lessonTimesSchoolFailed = '学校作息获取失败，已保留本地配置。';
  static const lessonTimesNoSchool = '未选择学校，可导入通用作息后再调整。';
  static const lessonTimesGeneralFailed = '通用作息获取失败，可手动配置每节课开始时间。';
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
  static const importByOcr = '使用OCR导入';
  static const importByOcrSubtitle = '识别课表图片后导入课程';
  static const importByPickupCode = '使用取件码导入';
  static const importByPickupCodeSubtitle = '输入取件码获取课程数据';
  static const importByAcademic = '教务系统导入';
  static const recognizingCourseImage = '正在上传图片并识别，请稍候';
  static const noCoursesRecognized = '未识别到课程';
  static String coursesImported(int count) => '成功导入 $count 门课程';
  static String ocrImportFailed(Object error) => 'OCR导入失败：$error';
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
  static const courseJsonHint = '粘贴课程 JSON 数组';
  static const help = '使用说明';
  static const exportJson = '导出JSON';
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
  static const invalidJsonInput = '输入的JSON格式错误';
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
  static const noCoursesToday = '今天没有课程安排';
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
  static const widgetNoCoursesToday = '今天暂无课程';
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
  static const chaoxingCollectQuestionsJs = r'''
(() => {
function clean(text) {
    return (text || '').replace(/\s+/g, ' ').trim();
}

function textOf(el) {
    if (!el) return '';
    const cloned = el.cloneNode(true);
    cloned.querySelectorAll(`
        .stuAnswerContent, .rightAnswerContent, .qtAnalysis, .analysis,
        .answer, .answerCon, .mark_answer, .marking_dui, .marking_cuo,
        .totalScore, .score, .Py_answer, .Py_answerRight, .Py_answerWrong
    `).forEach(x => x.remove());
    return clean(cloned.textContent);
}

function imagesOf(el, doc) {
    return Array.from((el || doc).querySelectorAll('img')).map((img, i) => ({
        index: i + 1,
        src: img.getAttribute('src') || img.getAttribute('data-original') || img.getAttribute('data-src') || '',
        alt: img.getAttribute('alt') || ''
    })).filter(x => x.src);
}

function questionTypeFromCode(value) {
    const code = parseInt(value, 10);
    const map = {
        0: '单选题',
        1: '多选题',
        2: '简答题',
        3: '判断题',
        4: '填空题',
        5: '名词解释',
        6: '论述题',
        7: '计算题',
        8: '其他题',
        9: '分录题',
        10: '资料题',
        11: '连线题',
        14: '完形填空题',
        15: '阅读理解题'
    };
    return map[code] || '';
}

function guessType(text, container) {
    const typeInput = container && container.querySelector('input[id^="answertype"], input[name^="type"]');
    const inputType = questionTypeFromCode(typeInput && typeInput.value);
    if (inputType) return inputType;

    const m = clean(text).match(/(单选题|多选题|判断题|填空题|简答题|问答题|论述题|计算题|名词解释|资料题|材料题|其他题|分录题|连线题|阅读理解题|完形填空题)/);
    return m ? m[1] : '未知题型';
}

function guessNumber(text, index) {
    const m = clean(text).match(/^\s*(\d+)\s*[\.、]|第\s*(\d+)\s*题/);
    return m ? (m[1] || m[2]) : String(index);
}

function isChoiceType(type) {
    return /单选题|多选题|判断题|阅读理解题|完形填空题/.test(type || '');
}

function badOption(text) {
    return !text || /正确答案[:：]|我的答案[:：]|答案解析[:：]|解析[:：]/.test(text);
}

function hasAnswerText(el) {
    const text = clean((el && (el.value || el.innerText || el.textContent)) || '');
    return text && !/未答|未作答|暂无|无/.test(text);
}

function isAnswered(container) {
    const checkedInput = Array.from(container.querySelectorAll('input[type="radio"], input[type="checkbox"]')).some(input =>
        input.checked === true ||
        input.defaultChecked === true ||
        input.getAttribute('checked') === 'checked'
    );
    if (checkedInput) return true;

    if (container.querySelector('[aria-checked="true"], [class*="check_answer"]')) {
        return true;
    }

    const answerBlocks = Array.from(container.querySelectorAll('.stuAnswerContent, .Py_answer, .mark_answer, .myAnswer, .my-answer'));
    if (answerBlocks.some(hasAnswerText)) {
        return true;
    }

    const textInputs = Array.from(container.querySelectorAll('textarea, input:not([type]), input[type="text"]'));
    if (textInputs.some(input => clean(input.value).length > 0)) {
        return true;
    }

    const editorFrames = Array.from(container.querySelectorAll('iframe'));
    for (const frame of editorFrames) {
        try {
            const body = frame.contentDocument && frame.contentDocument.body;
            if (hasAnswerText(body)) return true;
        } catch (e) {
            /* 跨域忽略 */
        }
    }

    return false;
}

function findContainers(doc) {
    const selectors = [
        '.questionLi', '.question-li', '.questionItem', '.question-item',
        '.TiMu', '.tiMu', '.question', '.work-question', '.mark_item', '.markItem',
        '.Cy_ulTop', '.py-mian1', '.zquestions .Py-mian1'
    ];

    for (const selector of selectors) {
        const nodes = Array.from(doc.querySelectorAll(selector));
        if (nodes.length) return nodes;
    }

    const set = new Set();
    doc.querySelectorAll('.mark_name, .qtContent, .questionStem, .stem').forEach(node => {
        let p = node;
        for (let i = 0; i < 5 && p; i++, p = p.parentElement) {
            if (p.innerText && p.innerText.length > 20) {
                set.add(p);
                break;
            }
        }
    });
    return Array.from(set);
}

function parseQuestion(container, index, doc) {
    const title = container.querySelector('.mark_name, .question-title, .tit, .stem-title, .clearfix');
    const stem = container.querySelector('.qtContent, .questionStem, .stem, .content');
    const baseText = textOf(title || container);

    const q = {
        number: guessNumber(baseText, index),
        type: guessType(baseText, container),
        content: textOf(stem || container),
        images: imagesOf(stem || container, doc),
        options: [],
        answered: isAnswered(container)
    };

    if (isChoiceType(q.type)) {
        const optionSelectors = [
            '.mark_letter li', '.qtDetail li', '.option li', '.options li',
            '.answerList li', '.choice li', '.ulTop li', 'li'
        ];

        for (const selector of optionSelectors) {
            const nodes = Array.from(container.querySelectorAll(selector)).filter(node => {
                const text = textOf(node);
                return !badOption(text) && (/^[A-H][\.、\s]/.test(text) || node.querySelector('input[type="radio"], input[type="checkbox"]'));
            });
            if (nodes.length >= 2) {
                q.options = nodes.map((node, i) => {
                    let text = textOf(node)
                        .replace(/正确答案[:：].*$/g, '')
                        .replace(/我的答案[:：].*$/g, '')
                        .replace(/答案[:：].*$/g, '')
                        .replace(/解析[:：].*$/g, '')
                        .trim();
                    return /^[A-H][\.、\s]/.test(text) ? text : `${String.fromCharCode(65 + i)}. ${text}`;
                }).filter(Boolean);
                break;
            }
        }
    }

    if (!stem) {
        q.options.forEach(opt => q.content = q.content.replace(opt, ''));
    }

    q.content = clean(q.content)
        .replace(/^\s*\d+\s*[\.、]\s*/, '')
        .replace(/^[\(（]\s*(单选题|多选题|判断题|填空题|简答题|问答题|论述题|计算题|名词解释|资料题|材料题|其他题|分录题|连线题|阅读理解题|完形填空题)\s*[\)）]\s*/, '')
        .trim();

    return q.content ? q : null;
}

function parseCurrentFrame(doc) {
    try {
        return findContainers(doc).map((container, index) => parseQuestion(container, index + 1, doc)).filter(Boolean);
    } catch (e) {
        return [];
    }
}

function collectQuestions(doc, depth, maxDepth) {
    if (depth > maxDepth) {
        return [];
    }

    let questions = parseCurrentFrame(doc);
    let frames = [];
    try {
        frames = Array.from(doc.querySelectorAll('iframe'));
    } catch (e) {
        frames = [];
    }

    for (let i = 0; i < frames.length; i++) {
        try {
            const frameDoc = frames[i].contentDocument || frames[i].contentWindow.document;
            if (frameDoc) {
                questions = questions.concat(collectQuestions(frameDoc, depth + 1, maxDepth));
            }
        } catch (e) {
            /* 跨域忽略 */
        }
    }

    return questions;
}

function uniqueQuestions(questions) {
    const result = [];
    const seen = new Set();
    for (const q of questions) {
        const key = JSON.stringify([q.type || '', q.content || '', q.options || []]);
        if (!seen.has(key)) {
            seen.add(key);
            result.push(q);
        } else if (q.answered) {
            const index = result.findIndex(item =>
                JSON.stringify([item.type || '', item.content || '', item.options || []]) === key
            );
            if (index !== -1 && !result[index].answered) {
                result[index] = q;
            }
        }
    }
    return result;
}

return JSON.stringify(uniqueQuestions(collectQuestions(document, 0, 6)));
})()
''';
  static const chaoxingAnswerJs = r'''
const targetNumber = String(arguments[0]);
const optionLetters = normalizeLetters(arguments[1]);
const textAnswers = normalizeTextAnswers(arguments[2]);
const targetType = String(arguments[3] || '');
function log(msg) {}

function normalizeLetters(value) {
    const raw = Array.isArray(value) ? value.join(',') : String(value || '');
    const normalized = raw.toUpperCase().replace(/[Ａ-Ｈ]/g, c => String.fromCharCode(c.charCodeAt(0) - 65248));
    const result = [];
    normalized.replace(/[A-H]/g, letter => {
        if (!result.includes(letter)) result.push(letter);
        return letter;
    });
    return result;
}

function normalizeTextAnswers(value) {
    const raw = Array.isArray(value) ? value : [value];
    return raw
        .map(item => String(item || '').trim())
        .filter(Boolean);
}

function clean(text) {
    return (text || '').replace(/\s+/g, ' ').trim();
}

function optionText(el) {
    return clean((el && (el.innerText || el.textContent)) || '');
}

function isChecked(optionElement) {
    const host = optionElement.closest ? (optionElement.closest('li') || optionElement) : optionElement;
    const input = host.querySelector ? host.querySelector('input[type="radio"], input[type="checkbox"]') : null;
    return input?.checked === true ||
        input?.getAttribute('checked') === 'checked' ||
        host.getAttribute?.('aria-checked') === 'true' ||
        /check_answer|checked|selected|active/.test(host.className || '');
}

function clickOption(optionElement, optionLetter) {
    if (!optionElement) return false;

    const host = optionElement.closest ? (optionElement.closest('li') || optionElement) : optionElement;
    let clickable = optionElement;
    if (optionElement.matches?.('li')) {
        clickable = optionElement.querySelector('a, label:not(.before), .after, input, span') || optionElement;
    } else if (!optionElement.matches?.('a, label, input, .after')) {
        clickable = optionElement.querySelector?.('a, label:not(.before), .after, input, span') || optionElement;
    }

    clickable.scrollIntoView?.({ behavior: 'smooth', block: 'center' });
    if (!isChecked(host)) {
        clickable.click();
    }

    if (!isChecked(host)) {
        const fallback = host.querySelector?.('a, label:not(.before), .after, input');
        if (fallback && fallback !== clickable) {
            fallback.click();
        }
    }

    log(`点击选项 ${optionLetter}: ${optionText(optionElement).substring(0, 50)}`);
    return true;
}

function dispatchTextEvents(el) {
    ['input', 'change', 'blur'].forEach(type => {
        try {
            el.dispatchEvent(new Event(type, { bubbles: true }));
        } catch (e) {
            /* 忽略事件兼容问题 */
        }
    });
}

function setTextValue(el, value) {
    if (!el || !value) return false;
    if (el.tagName === 'IFRAME') {
        try {
            const body = el.contentDocument && el.contentDocument.body;
            if (!body) return false;
            body.innerHTML = value;
            body.textContent = value;
            dispatchTextEvents(body);
            return true;
        } catch (e) {
            return false;
        }
    }

    if ('value' in el) {
        el.value = value;
    } else if (el.isContentEditable || el.getAttribute('contenteditable') === 'true') {
        el.innerHTML = value;
        el.textContent = value;
    } else {
        return false;
    }
    dispatchTextEvents(el);
    return true;
}

function findTextTargets(container) {
    const selectors = [
        'textarea',
        '.eidtDiv textarea',
        '.textDIV textarea',
        'input[type="text"]',
        'input:not([type])',
        '[contenteditable="true"]',
        '.edui-body-container',
        '.w-e-text',
        'iframe'
    ];
    const result = [];
    for (const selector of selectors) {
        container.querySelectorAll(selector).forEach(el => {
            if (!result.includes(el)) result.push(el);
        });
    }
    return result.filter(el => {
        const text = optionText(el);
        return !/正确答案[:：]|我的答案[:：]|答案解析[:：]|解析[:：]/.test(text);
    });
}

function fillTextAnswers(container) {
    if (textAnswers.length === 0) {
        log('未收到文本答案');
        return false;
    }

    const targets = findTextTargets(container);
    if (targets.length === 0) {
        log('未找到文本输入区域');
        return false;
    }

    let filled = 0;
    if (targets.length === 1) {
        filled += setTextValue(targets[0], textAnswers.join(' ')) ? 1 : 0;
    } else {
        const count = Math.min(targets.length, textAnswers.length);
        for (let i = 0; i < count; i++) {
            const answer = textAnswers[i];
            filled += setTextValue(targets[i], answer) ? 1 : 0;
        }
    }

    const saveButton = container.querySelector('[onclick*=saveQuestion]');
    if (saveButton) {
        try { saveButton.click(); } catch(e) { /* 保存按钮可不存在 */ }
    }

    return filled > 0;
}

function answerReaderOrFilling(container) {
    if (optionLetters.length === 0) return false;

    const lists = targetType.includes('完形')
        ? Array.from(container.querySelectorAll('.filling_answer'))
        : Array.from(container.querySelectorAll('.reading_answer'));
    if (lists.length === 0) return false;

    let clicked = 0;
    for (let i = 0; i < optionLetters.length; i++) {
        const item = lists[i];
        const letter = optionLetters[i];
        if (!item || !letter) continue;

        const target = item.querySelector(`span.saveSingleSelect[data="${letter}"], [data="${letter}"] a, [data="${letter}"]`);
        if (target) {
            target.click();
            clicked++;
        }
    }
    return clicked > 0;
}

function fillLineAnswers(container) {
    if (textAnswers.length === 0) return false;

    const boxes = Array.from(container.querySelectorAll('.line_answer_ct .selectBox'));
    if (boxes.length === 0) return false;

    let clicked = 0;
    for (let i = 0; i < boxes.length; i++) {
        const answer = textAnswers[i] || textAnswers[0];
        const box = boxes[i];
        const target = box.querySelector(`li[data="${answer}"] a, li[data="${answer}"]`);
        if (target) {
            target.click();
            clicked++;
        }
    }
    return clicked > 0;
}



// 递归遍历所有frame，找到指定题号的题目容器，然后找到对应选项并点击
function selectOptionByNumber(doc) {
    if (optionLetters.length === 0 && textAnswers.length === 0) {
        log('未收到有效答案');
        return false;
    }

    // 1. 查找所有题目容器（与用户原版相同的选择器）
    const questionSelectors = [
        '.questionLi', '.question-li', '.questionItem', '.question-item',
        '.TiMu', '.tiMu', '.question', '.work-question', '.mark_item', '.markItem'
    ];
    let containers = [];
    for (const sel of questionSelectors) {
        const elems = doc.querySelectorAll(sel);
        if (elems.length > 0) {
            containers = Array.from(elems);
            log(`使用选择器 "${sel}" 找到 ${containers.length} 个容器`);
            break;
        }
    }
    if (containers.length === 0) {
        // 备用：查找包含题干特征的元素（与用户原版相同）
        const titleNodes = doc.querySelectorAll('.mark_name, .qtContent, .stem-title');
        const set = new Set();
        titleNodes.forEach(node => {
            let p = node;
            for (let i = 0; i < 5 && p; i++) {
                if (p.innerText && p.innerText.length > 20) {
                    set.add(p);
                    break;
                }
                p = p.parentElement;
            }
        });
        containers = Array.from(set);
        log(`通过 mark_name 父级推断找到 ${containers.length} 个容器`);
    }
    if (containers.length === 0) {
        log('未找到任何题目容器');
        return false;
    }

    // 2. 根据题号匹配目标容器
    let targetContainer = null;
    for (const container of containers) {
        // 从容器中提取题号（优先从 .mark_name 等元素）
        const titleEl = container.querySelector('.mark_name, .question-title, .tit, .stem-title, .clearfix');
        let titleText = '';
        if (titleEl) {
            titleText = titleEl.innerText || titleEl.textContent || '';
        } else {
            titleText = container.innerText || container.textContent || '';
        }
        const match = titleText.match(/^\s*(\d+)\s*[\.、]|第\s*(\d+)\s*题/);
        let num = null;
        if (match) {
            num = match[1] || match[2];
            log(`提取到题号 ${num}，目标题号 ${targetNumber}`);
        }
        if (num && String(num) === targetNumber) {
            targetContainer = container;
            log(`找到匹配的题目容器，题号 ${num}`);
            break;
        }
    }
    if (!targetContainer) {
        log(`未找到题号为 ${targetNumber} 的容器`);
        return false;
    }

    if ((targetType.includes('阅读理解') || targetType.includes('完形填空')) && answerReaderOrFilling(targetContainer)) {
        return true;
    }

    if (targetType.includes('连线') && fillLineAnswers(targetContainer)) {
        return true;
    }

    if (optionLetters.length === 0) {
        return fillTextAnswers(targetContainer);
    }

    // 3. 查找选项列表（与用户原版相同）
    const optionSelectors = [
        'ul li .after', 'ul li label:not(.before)', '.answerBg .answer_p',
        '.answer_p', '.answerList.singleChoice li', '.clearfix.answerBg .fl.answer_p',
        '.stem_answer .answer_p', '.Zy_ulTop li a', '.mark_letter li', '.qtDetail li',
        '.option li', '.options li', '.answerList li', '.choice li', '.ulTop li', 'li'
    ];
    let options = null;
    for (const sel of optionSelectors) {
        const opts = targetContainer.querySelectorAll(sel);
        if (opts.length >= 2) {
            // 过滤掉明显不是选项的文本（如“正确答案：”）
            const filtered = Array.from(opts).filter(opt => {
                const text = optionText(opt);
                return text &&
                    !/正确答案[:：]/.test(text) &&
                    !/我的答案[:：]/.test(text) &&
                    !/答案解析[:：]|解析[:：]/.test(text);
            });
            if (filtered.length >= 2) {
                options = filtered;
                log(`选项选择器 "${sel}" 找到 ${options.length} 个选项`);
                break;
            }
        }
    }
    if (!options || options.length === 0) {
        log('未找到选项列表');
        return false;
    }

    let clicked = 0;
    for (const optionLetter of optionLetters) {
        const optionIndex = optionLetter.charCodeAt(0) - 65;
        if (optionIndex < 0 || optionIndex >= options.length) {
            log(`选项索引 ${optionIndex} 超出范围 (0-${options.length - 1})`);
            continue;
        }
        try {
            if (clickOption(options[optionIndex], optionLetter)) {
                clicked++;
            }
        } catch(e) {
            log(`点击失败: ${e.message}`);
        }
    }

    return clicked === optionLetters.length;
}

// 递归遍历所有frame
function findAndClickInFrames(doc) {
    if (selectOptionByNumber(doc)) return true;
    const frames = doc.querySelectorAll('iframe');
    for (let i = 0; i < frames.length; i++) {
        try {
            const frameDoc = frames[i].contentDocument;
            if (frameDoc && findAndClickInFrames(frameDoc)) {
                return true;
            }
        } catch(e) { /* 跨域忽略 */ }
    }
    return false;
}

const success = findAndClickInFrames(document);
return JSON.stringify({ success: success, expected: optionLetters.length });
''';
}
