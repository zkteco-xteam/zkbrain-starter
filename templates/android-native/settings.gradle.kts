rootProject.name = "ZKBrainAndroidNativeStarter"

pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
        
        // 🌟 仅当外部开发者配置了凭证时才启用远端 GitHub Packages，杜绝 Username must not be null 报错
        val gprUser = providers.gradleProperty("gpr.user").orNull ?: System.getenv("GITHUB_ACTOR")
        val gprKey = providers.gradleProperty("gpr.key").orNull ?: System.getenv("GITHUB_TOKEN")
        if (!gprUser.isNullOrBlank() && !gprKey.isNullOrBlank()) {
            maven {
                url = uri("https://maven.pkg.github.com/zkteco-xteam/zkbrain")
                credentials {
                    username = gprUser
                    password = gprKey
                }
            }
        }
    }
}
