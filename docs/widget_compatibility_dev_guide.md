# Flutter 桌面小组件兼容性开发文档

本文档面向当前 `Clark_AAMS` 项目，用于后续 Android 小组件兼容性开发、品牌适配和接口查找。

原则：
- 不改课程、登录、导入等核心业务
- 小组件逻辑只走统一入口
- 每次只适配一个品牌系统
- 每次修改后必须通过 `flutter analyze` 和本机 `android/gradlew assembleDebug`

---

## 1. 当前项目现状

### 1.1 Flutter 侧

小组件同步统一由 [`lib/widget/widget_service.dart`](../lib/widget/widget_service.dart) 管理。

当前职责：
- 从 `SharedPreferences` 读取课程数据
- 组装小组件 payload
- 调用 `home_widget` 写入数据并触发刷新
- 触发桌面固定小组件请求

### 1.2 Android 侧

当前使用：
- Kotlin
- `AppWidgetProvider`
- `RemoteViews`
- `home_widget`

入口在 [`android/app/src/main/AndroidManifest.xml`](../android/app/src/main/AndroidManifest.xml)。

---

## 2. 本项目涉及的接口清单

### 2.1 Flutter 公开接口

#### `WidgetService`

文件：[`lib/widget/widget_service.dart`](../lib/widget/widget_service.dart)

```dart
class WidgetService {
  static Future<void> updateWidget();
  static Future<bool> pinWidget();
}
```

用途：
- `updateWidget()`：写入小组件数据并刷新 Android Widget
- `pinWidget()`：请求系统固定小组件

### 2.2 `home_widget` 接口

当前项目会用到的接口：

```dart
HomeWidget.saveWidgetData<T>(String id, T? data, {bool deleteFile = true});
HomeWidget.updateWidget({String? name, String? androidName, String? iOSName, String? qualifiedAndroidName});
HomeWidget.isRequestPinWidgetSupported();
HomeWidget.requestPinWidget({String? name, String? androidName, String? qualifiedAndroidName});
```

用途：
- `saveWidgetData`：写入 Widget 数据到共享存储
- `updateWidget`：通知桌面刷新
- `isRequestPinWidgetSupported`：判断系统是否支持固定小组件
- `requestPinWidget`：请求系统添加小组件

### 2.3 SharedPreferences 键

当前项目使用的关键数据键：

| Key | 用途 |
|---|---|
| `class_schedule_settings` | 课表设置 |
| `class_schedule_courses` | 课程列表 |
| `course_widget_payload` | 小组件 payload |

### 2.4 Android 侧接口

#### `CourseWidgetProvider`

文件：[`android/app/src/main/kotlin/io/github/tissyboxc/widget/CourseWidgetProvider.kt`](../android/app/src/main/kotlin/io/github/tissyboxc/widget/CourseWidgetProvider.kt)

主要方法：

```kotlin
override fun onUpdate(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetIds: IntArray,
    widgetData: SharedPreferences,
)

override fun onAppWidgetOptionsChanged(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetId: Int,
    newOptions: Bundle,
)
```

用途：
- 接收系统刷新回调
- 根据尺寸选择 `widget_small` 或 `widget_medium`
- 从 payload 渲染 UI

#### `WidgetUpdateReceiver`

`WidgetUpdateReceiver : CourseWidgetProvider`

用途：
- AndroidManifest 中实际注册的 Widget Receiver

### 2.5 Android Manifest 接口

必须保留：

```xml
<activity>
    <intent-filter>
        <action android:name="es.antonborri.home_widget.action.LAUNCH" />
    </intent-filter>
</activity>

<receiver
    android:name=".widget.WidgetUpdateReceiver"
    android:exported="true"
    android:label="@string/course_widget_name">
    <intent-filter>
        <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
    </intent-filter>
    <meta-data
        android:name="android.appwidget.provider"
        android:resource="@xml/course_widget_info" />
</receiver>
```

### 2.6 Widget XML 接口

当前使用：

| 文件 | 用途 |
|---|---|
| `res/xml/course_widget_info.xml` | Widget 元信息 |
| `res/layout/widget_small.xml` | 小尺寸布局 |
| `res/layout/widget_medium.xml` | 中尺寸布局 |

当前布局 ID 依赖：
- `widget_root`
- `widget_small_content`
- `widget_small_empty`
- `widget_medium_content`
- `widget_medium_empty`

---

## 3. 数据流

标准数据流如下：

`Flutter` -> `SharedPreferences` -> `home_widget` -> `Android Widget`

禁止：
- Widget 直接请求网络
- Widget 自己维护独立课表缓存
- 业务页面直接调用底层 `MethodChannel`

---

## 4. 品牌兼容开发策略

### 4.1 ColorOS

目标：
- 小组件可添加
- 可刷新
- 后台不失效

开发重点：
- 保持 `updateWidget()` 在数据变更后立即执行
- 不依赖定时刷新
- 不引入复杂后台任务
- 确保点击行为只负责打开 App

重点验证：
- 桌面可添加
- App 更新后小组件刷新
- 锁屏后恢复正常显示

### 4.2 HyperOS

目标：
- 解决桌面更新延迟
- 避免 launcher 刷新异常

开发重点：
- 维持统一刷新入口
- 数据写入后立即更新 Widget
- App 前台恢复时补一次刷新

重点验证：
- 手动刷新成功
- launcher 正常接收更新
- 无需额外轮询任务

### 4.3 HarmonyOS

目标：
- 布局稳定
- 文字不截断

开发重点：
- 继续使用简单布局
- 文字必须单行或受控多行
- 长文本使用 ellipsis
- padding 保持固定

重点验证：
- 尺寸变化不乱版
- 课程名、时间、教室都可读

### 4.4 OriginOS

目标：
- 避免动态布局异常
- 避免文本裁切错位

开发重点：
- 优先显示课程名、时间、教室
- 小尺寸下优先保证主信息
- 不引入复杂嵌套

重点验证：
- 文本不溢出
- 小组件不空白

### 4.5 Samsung

目标：
- 处理 DPI 缩放和多分辨率

开发重点：
- 全部使用 `dp/sp`
- `previewLayout` 与真实布局一致
- 尽量避免依赖设备默认缩放

重点验证：
- 不同 DPI 下布局一致
- 点击行为正常

### 4.6 Pixel

目标：
- 作为基准机型验证

开发重点：
- Pixel 先验证标准行为
- 作为其他品牌的对照基线

重点验证：
- 可添加
- 可刷新
- 可点击打开 App

---

## 5. 当前允许修改的范围

允许修改：
- `lib/widget/widget_service.dart`
- `android/app/src/main/kotlin/io/github/tissyboxc/widget/*`
- `android/app/src/main/res/layout/*`
- `android/app/src/main/res/xml/*`
- `android/app/src/main/AndroidManifest.xml`

禁止修改：
- 课程业务逻辑
- 登录业务逻辑
- 导入业务逻辑
- 现有页面流程
- 存储结构的非必要变更

---

## 6. 推荐开发顺序

1. 先改最小接口
2. 只适配一个品牌
3. 验证 `flutter analyze`
4. 验证 `android/gradlew assembleDebug`
5. 再进入下一品牌

推荐顺序：
1. ColorOS
2. HyperOS
3. HarmonyOS
4. OriginOS
5. Samsung
6. Pixel

---

## 7. 修改前后的固定检查项

每次修改前先确认：
- 影响范围
- 修改文件
- 回滚方式
- 风险点

每次修改后必须确认：
- `flutter analyze` 通过
- `android/gradlew assembleDebug` 通过

---

## 8. 输出要求

后续如果继续做兼容性开发，建议每次都先输出：

### 本次目标
### 修改文件
### 修改原因
### 风险
### 回滚方式

---

## 9. 结论

当前项目的小组件兼容开发应坚持：
- 统一入口
- 最小侵入
- 单品牌逐步适配
- 每次修改后立即验证

