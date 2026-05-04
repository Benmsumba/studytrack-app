import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// Allow CI to inject signing config via environment variables.
val ciKeystorePath     = System.getenv("KEYSTORE_PATH")     ?: ""
val ciKeystorePassword = System.getenv("KEYSTORE_PASSWORD") ?: ""
val ciKeyAlias         = System.getenv("KEY_ALIAS")         ?: ""
val ciKeyPassword      = System.getenv("KEY_PASSWORD")      ?: ""
val hasCiKeystore      = ciKeystorePath.isNotEmpty()

android {
    namespace = "com.studytrack.app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.studytrack.app"
        minSdk = 21
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            when {
                // 1. CI: env vars injected by deploy_release.yml
                hasCiKeystore -> {
                    storeFile = file(ciKeystorePath)
                    storePassword = ciKeystorePassword
                    keyAlias = ciKeyAlias
                    keyPassword = ciKeyPassword
                }
                // 2. Local: key.properties file
                keystoreProperties["storeFile"] != null -> {
                    storeFile = file(keystoreProperties["storeFile"] as String)
                    storePassword = keystoreProperties["storePassword"] as String
                    keyAlias = keystoreProperties["keyAlias"] as String
                    keyPassword = keystoreProperties["keyPassword"] as String
                }
                // 3. Fallback: debug signing
                else -> initWith(getByName("debug"))
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isDebuggable = false
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
