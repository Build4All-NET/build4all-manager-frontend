plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
}

android {
    namespace = "com.buil4all.build4allmanager"
    compileSdk = (flutter.compileSdkVersion as Number).toInt()
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.buil4all.build4allmanager"
        minSdk = 23  // Firebase Messaging requires minSdk 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        release {
            keyAlias = System.getenv("ANDROID_KEY_ALIAS") ?: findProperty("keyAlias") as String?
            keyPassword = System.getenv("ANDROID_KEY_PASSWORD") ?: findProperty("keyPassword") as String?
            storeFile = file("${rootDir}/android/upload-keystore.jks")
            storePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD") ?: findProperty("storePassword") as String?
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            shrinkResources = false
            minifyEnabled = false
        }
    }
}

flutter {
    source = "../.."
}