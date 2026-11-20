plugins {
    kotlin("multiplatform") version "2.0.21"
    id("com.android.application") version "8.5.2"
    id("org.jetbrains.compose") version "1.7.0"
    id("org.jetbrains.kotlin.plugin.compose") version "2.0.21"
}

kotlin {
    androidTarget()
    jvm("desktop")

    sourceSets {
        commonMain.dependencies {
            implementation(compose.runtime)
            implementation(compose.foundation)
            implementation(compose.material)
            implementation(compose.ui)
            implementation(compose.components.resources)

            // 🌟 远程 Maven 依赖引入 (若配置了 GitHub Packages 凭据可取消注释)：
            // implementation("com.zkteco.zkbrain:zkbrain-android:1.2.0")
            
            // 协程支持
            implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.8.1")
        }
        
        androidMain.dependencies {
            implementation("androidx.activity:activity-compose:1.9.2")
            // 离线预编译 AAR 兜底 (Clone 后零配置直接跑通)
            implementation(fileTree(mapOf("dir" to "libs", "include" to listOf("*.aar"))))
        }
    }
}

android {
    namespace = "com.zkteco.zkbrain.starter"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.zkteco.zkbrain.starter"
        minSdk = 24
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
    }
}
