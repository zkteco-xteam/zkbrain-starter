rootProject.name = "ZKBrainKmpTemplate"

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
        // 🌟 引入 ZKBrain GitHub Packages 官方发布源 (或公司私有 Maven 仓库)
        maven {
            url = uri("https://maven.pkg.github.com/zkteco-xteam/zkbrain")
            credentials {
                username = providers.gradleProperty("gpr.user").orNull ?: System.getenv("GITHUB_ACTOR")
                password = providers.gradleProperty("gpr.key").orNull ?: System.getenv("GITHUB_TOKEN")
            }
        }
    }
}
