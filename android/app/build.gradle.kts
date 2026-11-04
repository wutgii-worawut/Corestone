import java.util.Properties

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing comes from android/key.properties, which stays out of git.
// See TEMPLATE.md "Release signing".
val keystoreProperties =
    Properties().apply {
        val file = rootProject.file("key.properties")
        if (file.exists()) file.inputStream().use { load(it) }
    }

android {
    namespace = "com.wutstack.corestone"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // flutter_local_notifications needs java.time on older Android.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.wutstack.corestone"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        testInstrumentationRunner = "pl.leancode.patrol.PatrolJUnitRunner"
        // Each Patrol test starts from a freshly installed app.
        testInstrumentationRunnerArguments["clearPackageData"] = "true"
    }

    testOptions {
        execution = "ANDROIDX_TEST_ORCHESTRATOR"
    }

    buildFeatures {
        resValues = true
    }

    flavorDimensions += "env"
    // deepLinkHost must equal DEEP_LINK_HOST in config/<flavor>.json and
    // ios/Flutter/*-<flavor>.xcconfig; deep_link_host_test checks it.
    productFlavors {
        create("dev") {
            dimension = "env"
            applicationIdSuffix = ".dev"
            resValue("string", "app_name", "Corestone Dev")
            manifestPlaceholders["deepLinkHost"] = "dev.links.example.com"
        }
        create("stage") {
            dimension = "env"
            applicationIdSuffix = ".stage"
            resValue("string", "app_name", "Corestone Stage")
            manifestPlaceholders["deepLinkHost"] = "stage.links.example.com"
        }
        create("prod") {
            dimension = "env"
            resValue("string", "app_name", "Corestone")
            manifestPlaceholders["deepLinkHost"] = "links.example.com"
        }
    }

    signingConfigs {
        if (!keystoreProperties.isEmpty) {
            create("release") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig =
                if (keystoreProperties.isEmpty) {
                    // Keeps local and template release builds working. Quiet
                    // level, because Flutter runs Gradle with -q.
                    logger.quiet(
                        "WARNING: android/key.properties not found; release builds are signed with the debug key. See TEMPLATE.md \"Release signing\".",
                    )
                    signingConfigs.getByName("debug")
                } else {
                    signingConfigs.getByName("release")
                }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

// A flavor without android/app/src/<flavor>/google-services.json still
// builds, with push off.
googleServices {
    missingGoogleServicesStrategy =
        com.google.gms.googleservices.GoogleServicesPlugin.MissingGoogleServicesStrategy.WARN
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    androidTestUtil("androidx.test:orchestrator:1.5.1")
}
