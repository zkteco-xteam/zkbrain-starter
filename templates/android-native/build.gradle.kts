plugins {
    id("com.android.application") version "8.5.2"
    id("org.jetbrains.kotlin.android") version "2.0.21"
}

android {
    namespace = "com.zkteco.zkbrain.nativeapp"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.zkteco.zkbrain.nativeapp"
        minSdk = 24
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
    }

    buildFeatures {
        viewBinding = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("com.google.android.material:material:1.12.0")
    implementation("androidx.constraintlayout:constraintlayout:2.1.4")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.6")

    // 🌟 核心依赖 (双轨支持)：
    // 方式 A (推荐开箱即用)：内置预编译官方 AAR，克隆即可离线编译跑通
    implementation(fileTree(mapOf("dir" to "libs", "include" to listOf("*.aar", "*.jar"))))

    // 🌟 ZKBrain 运行时必需底层依赖 (若采用本地 AAR 方式，需保留以下传递依赖)：
    implementation("no.nordicsemi.android.kotlin.ble:scanner:1.0.1")
    implementation("no.nordicsemi.android.kotlin.ble:client:1.0.1")
    implementation("no.nordicsemi.android.kotlin.ble:core:1.0.1")
    implementation("androidx.security:security-crypto:1.1.0-alpha06")
    implementation("co.touchlab:kermit:2.0.4")
    implementation("com.squareup.okio:okio:3.17.0")
    implementation("org.korge:korlibs-crypto:6.1.0")
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.7.3")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.8.1")

    // 方式 B (远程 Maven 发布依赖，需在 ~/.gradle/gradle.properties 配置 gpr.user 与 gpr.key)：
    // implementation("com.zkteco.zkbrain:zkbrain-android:1.2.0")
}
