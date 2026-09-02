plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseSigningEnvNames = mapOf(
    "storeFile" to "ROUTEMAKER_UPLOAD_STORE_FILE",
    "storePassword" to "ROUTEMAKER_UPLOAD_STORE_PASSWORD",
    "keyAlias" to "ROUTEMAKER_UPLOAD_KEY_ALIAS",
    "keyPassword" to "ROUTEMAKER_UPLOAD_KEY_PASSWORD",
)
val releaseSigningValues = releaseSigningEnvNames.mapValues { (_, envName) ->
    System.getenv(envName)?.takeIf { it.isNotBlank() }
}
val isReleaseBuild = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}

if (isReleaseBuild) {
    val missingVariables = releaseSigningValues
        .filterValues { it == null }
        .keys
        .map { releaseSigningEnvNames.getValue(it) }
    if (missingVariables.isNotEmpty()) {
        throw GradleException(
            "Release signing environment variables are missing: ${missingVariables.joinToString()}",
        )
    }
}

android {
    namespace = "com.techtour.flutterprojects"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.techtour.flutterprojects"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            releaseSigningValues["storeFile"]?.let { storeFile = file(it) }
            storePassword = releaseSigningValues["storePassword"]
            keyAlias = releaseSigningValues["keyAlias"]
            keyPassword = releaseSigningValues["keyPassword"]
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
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
