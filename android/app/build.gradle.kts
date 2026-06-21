import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load release signing credentials from key.properties (never committed to git)
val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()
if (keyPropertiesFile.exists()) {
    keyProperties.load(FileInputStream(keyPropertiesFile))
}

android {
    namespace = "com.fitforge.fitforge"
    dependenciesInfo {
        includeInApk = false
        includeInBundle = false
    }
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Required by flutter_local_notifications (#2)
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.fitforge.fitforge"
        minSdk = flutter.minSdkVersion  // Required for flutter_secure_storage EncryptedSharedPreferences
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keyPropertiesFile.exists()) {
            create("release") {
                keyAlias = keyProperties["keyAlias"] as String
                keyPassword = keyProperties["keyPassword"] as String
                storeFile = file(keyProperties["storeFile"] as String)
                storePassword = keyProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keyPropertiesFile.exists())
                signingConfigs.getByName("release")
            else
                signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Required for flutter_local_notifications on minSdk < 26 (#2)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

// Exclude Google Play Core from all configurations — not present in F-Droid builds
configurations.all {
    exclude(group = "com.google.android.play", module = "core")
    exclude(group = "com.google.android.play", module = "core-common")
    exclude(group = "com.google.android.play", module = "core-ktx")
}

// ABI-split versionCode scheme for F-Droid + rename output APK.
// Each split APK gets versionCode = base * 10 + abiCode so F-Droid can ship
// one APK per ABI (see metadata VercodeOperation).
val abiCodes = mapOf("armeabi-v7a" to 1, "arm64-v8a" to 2, "x86_64" to 3)
android.applicationVariants.all {
    val variant = this
    outputs.all {
        val output = this as com.android.build.gradle.internal.api.BaseVariantOutputImpl
        val abi = output.filters.find {
            it.filterType == com.android.build.api.variant.FilterConfiguration.FilterType.ABI.name
        }?.identifier
        val abiCode = abiCodes[abi]
        if (abiCode != null) {
            (output as com.android.build.gradle.internal.api.ApkVariantOutputImpl).versionCodeOverride =
                variant.versionCode * 10 + abiCode
        }
        val abiSuffix = if (abi != null) "-$abi" else ""
        output.outputFileName = "fitforge-${versionName}${abiSuffix}-${buildType.name}.apk"
    }
}
