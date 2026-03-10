import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
   
}

// ✅ Load keystore properties from android/key.properties
val keyProperties = Properties()
val keyPropertiesFile = rootProject.file("key.properties")
if (keyPropertiesFile.exists()) {
    keyProperties.load(keyPropertiesFile.inputStream())
}

android {
    namespace = "com.buil4all.build4allmanager"
    compileSdk = flutter.compileSdkVersion
    //ndkVersion = flutter.ndkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
    applicationId = "com.buil4all.build4allmanager"
   minSdkVersion flutter.minSdkVersion
    targetSdk = flutter.targetSdkVersion
    versionCode = flutter.versionCode
    versionName = flutter.versionName
}

    // ✅ Release signing (your keystore)
signingConfigs {
    create("release") {
        keyAlias = keyProperties["keyAlias"] as String
        keyPassword = keyProperties["keyPassword"] as String
        storeFile = rootProject.file(keyProperties["storeFile"] as String)
        storePassword = keyProperties["storePassword"] as String
    }
}


    // ✅ ONE buildTypes block فقط — no debug signing here
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false

        }
        debug {
            // default debug config (no need to add anything)
        }
    }
}

flutter {
    source = "../.."
}
