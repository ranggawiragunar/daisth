import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseSigningProperties = Properties()
val releaseSigningPropertiesFile = rootProject.file("key.properties")
if (releaseSigningPropertiesFile.isFile) {
    releaseSigningPropertiesFile.inputStream().use { input ->
        releaseSigningProperties.load(input)
    }
}
val releaseSigningKeys = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
val hasAnyReleaseSigningValue = releaseSigningKeys.any {
    !releaseSigningProperties.getProperty(it).isNullOrBlank()
}
val hasAllReleaseSigningValues = releaseSigningKeys.all {
    !releaseSigningProperties.getProperty(it).isNullOrBlank()
}
if (hasAnyReleaseSigningValue && !hasAllReleaseSigningValues) {
    throw GradleException(
        "android/key.properties is incomplete; provide storeFile, storePassword, keyAlias, and keyPassword."
    )
}
val releaseKeystore = if (hasAllReleaseSigningValues) {
    rootProject.file(releaseSigningProperties.getProperty("storeFile"))
} else {
    null
}
if (releaseKeystore != null && !releaseKeystore.isFile) {
    throw GradleException("The release keystore configured in android/key.properties was not found.")
}

android {
    namespace = "com.rendev.daisth"

    signingConfigs {
        if (hasAllReleaseSigningValues) {
            create("release") {
                storeFile = requireNotNull(releaseKeystore)
                storePassword = releaseSigningProperties.getProperty("storePassword")
                keyAlias = releaseSigningProperties.getProperty("keyAlias")
                keyPassword = releaseSigningProperties.getProperty("keyPassword")
            }
        }
    }
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.rendev.daisth"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Build unsigned until a developer-owned upload key is configured locally.
            signingConfig = if (hasAllReleaseSigningValues) {
                signingConfigs.getByName("release")
            } else {
                null
            }
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
