# 构建与发布约定

本文件记录**本机强制约定**与 CI 行为，改动前请先读。

## 1. 工具链：只用本地，禁止联网下载

| 用途 | 强制路径 | 说明 |
|---|---|---|
| Gradle | `D:\service\gradle-9.4.1` | 用 `bin\gradle` 直接调用；不使用 wrapper 联网下载 |
| Gradle 缓存 | `GRADLE_USER_HOME=D:\service\gradle-home` | 依赖只装这里，不污染 `~/.gradle` |
| Flutter | `D:\service\flutter` | `bin\flutter` |
| Dart | `D:\service\dart-sdk` | `bin\dart` |
| Pub 缓存 | `PUB_CACHE=D:\service\pub-cache` | 包只装这里 |
| Android SDK | `D:\service\clarkaitoy-build\toolchains\android-sdk` | 已装 platform 34/35/36/36.1，**无 37** |

**编译产物统一放 `D:\service\clark_aams\aams_builded\`**：

```
aams_builded/
├── app/             app-release.apk
├── backend/         Clark_AAMS_Backend-0.0.1-SNAPSHOT.jar
└── frontend-dist/   vite build 产物
```

## 2. 本机构建命令

### 后端（Spring Boot 4.0.6 / Java 21）

```bash
cd D:/service/clark_aams/Clark_AAMS_Backend
export GRADLE_USER_HOME=D:/service/gradle-home
D:/service/gradle-9.4.1/bin/gradle bootJar          # 产物 build/libs/*.jar
D:/service/gradle-9.4.1/bin/gradle test             # 单测
```

> 注意：`gradle/wrapper/gradle-wrapper.properties` 已改为官方远程地址
> （原先是本机绝对路径 `file:///D:/...`，CI 无法使用）。
> **本机请直接用 `D:/service/gradle-9.4.1/bin/gradle`，不要调 `gradlew`**，
> 否则会触发 wrapper 下载。

### App（Flutter 3.41.9 / Dart 3.11.5）

```bash
cd D:/service/clark_aams/Clark_AAMS
export PUB_CACHE=D:/service/pub-cache
D:/service/flutter/bin/flutter pub get --offline
D:/service/flutter/bin/flutter build apk --release
# 产物 build/app/outputs/flutter-apk/app-release.apk
```

已修复的两个构建阻塞点（勿回退）：

1. **JVM target**：`android/build.gradle.kts` 里统一把含 `android` 扩展的模块
   设为 Java 17，并把所有 `KotlinCompile.jvmTarget` 设为 `JVM_17`。
   否则 `:home_widget:compileReleaseKotlin` 报
   "Cannot inline bytecode built with JVM target 11 into ... 1.8"。
   该块**必须在** `evaluationDependsOn(":app")` **之前**注册。
2. **glance 动态版本**：`android/app/build.gradle.kts` 把
   `androidx.glance:glance-appwidget` / `:glance` 钉死到 `1.1.1` 并 `force`。
   `home_widget 0.9.1` 声明的是 `1.+`，会拉到要求 `compileSdk 37` 的版本，
   而本机与 AGP 8.11.1 都只到 36。

### 前端（React 19 / Vite 8 / TS 6）

```bash
cd D:/service/clark_aams/Clark_AAMS_Frontend
./node_modules/.bin/tsc -b
./node_modules/.bin/vite build --outDir D:/service/clark_aams/aams_builded/frontend-dist --emptyOutDir
```

## 3. Git：三个仓库

| 仓库 | 说明 |
|---|---|
| [TissyBoxC/Clark_AAMS](https://github.com/TissyBoxC/Clark_AAMS) | Flutter App |
| [TissyBoxC/Clark_AAMS_Backend](https://github.com/TissyBoxC/Clark_AAMS_Backend) | Spring Boot 后端 |
| [TissyBoxC/Clark_AAMS_Frontend](https://github.com/TissyBoxC/Clark_AAMS_Frontend) | React Web（2026-10 首次纳入 git） |

### 关键：git 必须走 HTTP/1.1

本机 `github.com:443` 在 HTTP/2 下会 `Recv failure: Connection was reset`，
表现为 `git push` 直接失败。已全局设置：

```bash
git config --global http.version HTTP/1.1
```

**新机器/新环境必须重新设置**，否则 push 不通。

### 提交规范

Conventional Commits，**中文正文**，需说明：为什么改、改了什么、
风险/影响、如何验证。示例见各仓库近期的 commit。

- `feat(scope): ` 新功能
- `fix(scope): ` 缺陷修复
- `refactor(scope): ` 重构（不改外部行为）
- `build(scope): ` 构建/依赖
- `ci: ` 流水线
- `docs: ` 文档

**版本更新即打 tag 并推送**，CI 会据此自动发布 Release。

## 4. CI：GitHub Actions

三个仓库各有 `.github/workflows/release.yml`，行为一致：

| 触发 | 行为 |
|---|---|
| push 到 `main` | 构建 + 上传 artifact（**不发布 Release**） |
| push tag `v*` | 构建 + **自动发布 Release**（附产物与 Release Notes） |
| 手动 `workflow_dispatch` | 可指定版本号，构建并发布 |

### 发布流程

```bash
# 1. 改版本号
#    App: pubspec.yaml 的 version: 1.1.0+18
cd D:/service/clark_aams/Clark_AAMS && git tag -a v1.1.2 -m "..." && git push origin v1.1.2
```

tag 推送后 CI 产出：

- **App**：`Clark_AAMS_v1.1.2_universal.apk` + `arm64-v8a` / `armeabi-v7a` / `x86_64` 分包
- **Backend**：`Clark_AAMS_Backend_v1.0.0.jar`（可执行）
- **Frontend**：`Clark_AAMS_Frontend_v1.0.0.tar.gz`（`dist` 静态站点）

### 签名

App 当前用仓库内 **debug 签名**（`android/app/build.gradle.kts` 的默认配置）。
要改成正式签名，在 `Clark_AAMS` 仓库配置这些 secrets：

- `ANDROID_KEYSTORE_BASE64`（密钥库文件的 base64）
- `ANDROID_STORE_PASSWORD`
- `ANDROID_KEY_PASSWORD`
- `ANDROID_KEY_ALIAS`

配好后 CI 自动启用正式签名，无需改 workflow。

### 已知放宽项

后端 `test`、前端 `tsc -b` / `lint`、App `flutter analyze` **目前
`continue-on-error`**，只记录不阻断，避免历史问题挡住发布。
待清理后再逐步收紧为阻断。

## 5. 常见坑

| 现象 | 原因 | 处理 |
|---|---|---|
| `git push` 报 Connection was reset | HTTP/2 | `git config --global http.version HTTP/1.1` |
| CI run 秒失败且 `total_count: 0` | workflow 解析失败 | 检查是否在 `if:` 里用了 `secrets.` |
| `gradlew` 卡住下载 | wrapper 指向远程 | 本机改用 `D:/service/gradle-9.4.1/bin/gradle` |
| `checkReleaseAarMetadata` 要求 SDK 37 | glance 动态版本 | 确认 `force 1.1.1` 仍在 |
| `Cannot inline bytecode ... 1.8` | 插件模块 jvmTarget | 确认 `subprojects` 块在 `evaluationDependsOn` 之前 |
