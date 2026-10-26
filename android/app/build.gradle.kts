plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "io.github.tissyboxc"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "io.github.tissyboxc"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // 原为 2.10.3。离线构建环境里只缓存了 2.12.0，
    // Gradle 断网时无法解析未缓存的版本，因此对齐到本地已有版本。
    implementation("androidx.work:work-runtime-ktx:2.12.0")

    // home_widget 0.9.1 用 "androidx.glance:glance-appwidget:1.+" 这种动态版本，
    // 会拉到需要 compileSdk 37 的新版 glance，而 AGP 8.11.1 最高只到 36，
    // 导致 :app:checkReleaseAarMetadata 失败。此处钉死到与 compileSdk 36 兼容的版本。
    implementation("androidx.glance:glance-appwidget:1.1.1")
    implementation("androidx.glance:glance:1.1.1")
}

// 兜底：即使某个插件再次引入动态版本，也统一收敛到上面钉死的版本。
configurations.all {
    resolutionStrategy {
        force("androidx.glance:glance-appwidget:1.1.1")
        force("androidx.glance:glance:1.1.1")

        // home_widget 0.9.1 用 "androidx.work:work-runtime-ktx:2.+" 和
        // "kotlinx-coroutines-android:1.+" 这种动态版本声明依赖。
        // 解析动态版本需要拉 maven-metadata.xml，断网构建会直接失败。
        // 这里钉死到本地缓存已有的版本，离线也能构建。
        force("androidx.work:work-runtime-ktx:2.12.0")
        force("androidx.work:work-runtime:2.12.0")
        force("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.11.0")
    }
}
