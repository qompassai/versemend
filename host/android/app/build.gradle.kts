// Owned Android packaging template — app module.
//
// The Rust cdylib is built by cargo (see the crate .cargo/config.toml for
// the NDK linkers) into <crate>/target/<triple>/release/. The
// syncAndroidLibs task copies it into the standard jniLibs layout before
// any packaging task runs. SDK/NDK come from the environment
// (ANDROID_SDK_ROOT / ANDROID_NDK_ROOT or local.properties) — this project
// never downloads a toolchain.

plugins {
    id("com.android.application")
}

// Name of the cargo cdylib (crate lib name, hyphen -> underscore).
val rustLibName = "libversemend.so"
// ABI -> cargo target triple.
val abiTriples = linkedMapOf(
    "arm64-v8a" to "aarch64-linux-android",
    "x86_64" to "x86_64-linux-android",
)

val syncAndroidLibs by tasks.registering(Copy::class) {
    val cargoTargetDir = rootProject.projectDir.parentFile.resolve("target")
    abiTriples.forEach { (abi, triple) ->
        from(cargoTargetDir.resolve("$triple/release/$rustLibName")) {
            into(abi)
        }
    }
    into(layout.projectDirectory.dir("src/main/jniLibs"))
}

tasks.named("preBuild") { dependsOn(syncAndroidLibs) }

android {
    namespace = "ai.qompass.versemend"
    compileSdk = 36
    // Pinned to an NDK installed in the system SDK; AGP resolves it from
    // ANDROID_SDK_ROOT, never by downloading one.
    ndkVersion = "28.0.12674087"

    defaultConfig {
        applicationId = "ai.qompass.versemend"
        minSdk = 26
        // targetSdk is a free parameter: it is set here, in the manifest
        // layer, and backed by a compileSdk-36 build. Raise it as Play
        // raises its floor — one line, no toolchain change.
        targetSdk = 36
        versionCode = 1
        versionName = "1.0.0"

        ndk {
            abiFilters += abiTriples.keys
        }
    }

    signingConfigs {
        // THROWAWAY signing identity for proofs and CI only.
        // Production signing is a release-time decision: replace this
        // block with the real keystore (kept out of the repo).
        create("throwaway") {
            storeFile = rootProject.file("throwaway.keystore")
            storePassword = "throwaway"
            keyAlias = "throwaway"
            keyPassword = "throwaway"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("throwaway")
            isMinifyEnabled = false
        }
    }
}

dependencies {
    // GameActivity variant: AGDK GameActivity as an ordinary Gradle
    // dependency (androidx.games, Google Maven). Version pairing is set
    // by the Rust android-activity crate: 0.6.x supports games-activity
    // 4.4.0 (backwards compatible with 4.0.0). Do NOT enable buildFeatures
    // prefab — android-activity ships its own native glue.
    implementation("androidx.games:games-activity:4.4.0")
    // GameActivity extends AppCompatActivity, but the games-activity
    // 4.4.0 POM declares no dependencies at all — AppCompat (and its
    // Theme.AppCompat resources) must be declared by the app itself.
    implementation("androidx.appcompat:appcompat:1.7.1")
}
