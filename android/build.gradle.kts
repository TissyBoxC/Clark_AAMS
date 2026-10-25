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
