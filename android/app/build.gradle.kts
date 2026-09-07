import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Read secrets from local.properties (gitignored) rather than committing them
// to AndroidManifest.xml directly.
val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    FileInputStream(localPropertiesFile).use { localProperties.load(it) }
}
val mapsApiKey: String = localProperties.getProperty("MAPS_API_KEY") ?: ""

// Release signing credentials live in android/key.properties (gitignored).
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

// `storeFile` may be absolute, or relative to the Flutter project root. `file()`
// inside this module resolves against android/app, so try every sensible base —
// a mistyped path must fail loudly rather than quietly reverting to debug keys.
fun resolveKeystore(path: String): File? = listOf(
    File(path),
    File(rootProject.projectDir.parentFile, path), // Flutter project root
    File(rootProject.projectDir, path),            // android/
    File(projectDir, path),                        // android/app/
).firstOrNull { it.isFile }

val releaseKeystore: File? = if (keystorePropertiesFile.exists()) {
    val configured = keystoreProperties.getProperty("storeFile")
        ?: throw GradleException("android/key.properties is missing `storeFile`.")
    resolveKeystore(configured) ?: throw GradleException(
        "Keystore \"$configured\" from android/key.properties was not found. " +
            "Fix the path, or delete key.properties to build unsigned debug-key releases."
    )
} else {
    null
}

android {
    namespace = "com.globelink.driver"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.globelink.driver"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["mapsApiKey"] = mapsApiKey
    }

    signingConfigs {
        if (releaseKeystore != null) {
            create("release") {
                storeFile = releaseKeystore
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (releaseKeystore != null) {
                signingConfigs.getByName("release")
            } else {
                // Keeps `flutter run --release` working on a machine without the
                // keystore. Play rejects anything signed this way, so say so loudly
                // rather than letting a debug-signed bundle reach the console.
                logger.warn(
                    "WARNING: android/key.properties not found - signing the release " +
                        "build with DEBUG keys. This artifact CANNOT be uploaded to Play."
                )
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
