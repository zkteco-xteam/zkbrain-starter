plugins {
    id("com.android.application") version "8.5.2"
    id("org.jetbrains.kotlin.android") version "2.0.21"
    id("org.jetbrains.kotlin.plugin.compose") version "2.0.21"
}

android {
    namespace = "com.zkteco.zkbrain.composeapp"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.zkteco.zkbrain.composeapp"
        minSdk = 26
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
    }

    buildFeatures {
        compose = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
        freeCompilerArgs += listOf("-Xskip-metadata-version-check")
    }

    packaging {
        jniLibs {
            keepDebugSymbols += listOf("**/*.so")
        }
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.6")
    implementation("androidx.activity:activity-compose:1.9.2")

    // Jetpack Compose BOM & UI
    implementation(platform("androidx.compose:compose-bom:2024.09.00"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-graphics")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.8.6")

    // Core BCI SDK: Dual-track dependency support
    // Option A (Recommended out-of-the-box): Bundled prebuilt official AAR for offline builds
    implementation(fileTree(mapOf("dir" to "libs", "include" to listOf("*.aar", "*.jar"))))
    // Transitive dependencies required when using local AAR:
    implementation("no.nordicsemi.android.kotlin.ble:scanner:1.0.1")
    implementation("no.nordicsemi.android.kotlin.ble:client:1.0.1")
    implementation("no.nordicsemi.android.kotlin.ble:core:1.0.1")
    implementation("androidx.security:security-crypto:1.1.0-alpha06")
    implementation("co.touchlab:kermit:2.0.4")
    implementation("com.squareup.okio:okio:3.17.0")
    implementation("org.korge:korlibs-crypto:6.1.0")
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.7.3")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.8.1")

    // Option B (Maven Central direct import):
    // implementation("io.github.zkteco-xteam:zkbrain-android:1.2.1")
}
