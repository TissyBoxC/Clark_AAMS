allprojects {
    repositories {
        maven { url = uri("https://maven.aliyun.com/repository/public/") }
        maven { url = uri("https://maven.aliyun.com/repository/google/") }
        maven { url = uri("https://maven.aliyun.com/repository/gradle-plugin/") }
        maven { url = uri("https://maven.aliyun.com/repository/central/") }
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
// 统一所有模块（含插件模块，如 home_widget）的 JVM target。
// 背景：home_widget 0.9.1 自带的 Kotlin 字节码以 JVM 11 编译，若宿主模块
// 仍用默认的 1.8，会在 :home_widget:compileReleaseKotlin 报
// "Cannot inline bytecode built with JVM target 11 into bytecode ... 1.8"。
// 注意：必须在下面的 evaluationDependsOn(":app") 之前注册 afterEvaluate，
// 否则子项目已求值完成，afterEvaluate 会直接报错。
subprojects {
    // 全局钉死插件带入的动态版本。
    // 背景：home_widget 0.9.1 用 "1.+" / "2.+" 声明依赖，解析这类版本
    // 必须先拉 maven-metadata.xml，离线构建会直接失败。
    // 只在 :app 里 force 不够——:home_widget 自己的 compileClasspath
    // 同样会去解析动态版本，所以必须在这个层级统一收敛。
    configurations.all {
        resolutionStrategy {
            force("androidx.glance:glance-appwidget:1.1.1")
            force("androidx.glance:glance:1.1.1")
            force("androidx.work:work-runtime-ktx:2.12.0")
            force("androidx.work:work-runtime:2.12.0")
            force("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.11.0")
        }
    }
}

subprojects {
    afterEvaluate {
        extensions.findByName("android")?.let {
            (it as? com.android.build.gradle.BaseExtension)?.compileOptions?.apply {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
