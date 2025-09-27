plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") version "4.4.1"
    id("com.google.android.libraries.mapsplatform.secrets-gradle-plugin")
}

android {
    namespace = "com.example.campusapp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        // Required for google_navigation_flutter when minSdk < 34
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.campusapp"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // for all languages supported by the Navigation SDK.
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("com.google.android.libraries.navigation:navigation:6.2.2")
    // Desugaring library for java.time APIs etc.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs_nio:2.0.4")
    
}

// Configure secrets plugin
secrets {
    // File ignored from VCS (create manually): contains real keys
    propertiesFileName = "secrets.properties"
    // Fallback (commit this): contains DEFAULT_* placeholders so build won't fail
    defaultPropertiesFileName = "local.defaults.properties"
}
