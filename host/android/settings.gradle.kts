// Owned Android packaging template — settings.
// Repositories are declared here (dependencyResolutionManagement) so the
// build consumes exactly: Google Maven (AGP, AndroidX/AGDK) + Maven Central.
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "versemend-android"
include(":app")
