plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

import java.util.Properties

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { localProperties.load(it) }
}

val flutterVersionCode = localProperties.getProperty("flutter.versionCode")?.toIntOrNull() ?: 1
val flutterVersionName = localProperties.getProperty("flutter.versionName") ?: "1.0"

android {
    namespace = "com.example.live_location_tracker"
    compileSdk = 34
    ndkVersion = "26.1.10909125"

    // Dependency resolution strategy
    configurations.all {
        resolutionStrategy {
            force("com.google.android.gms:play-services-base:18.3.0")
            force("com.google.android.gms:play-services-location:21.1.0")
            force("com.google.android.gms:play-services-maps:18.2.0")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    sourceSets {
        getByName("main").java.srcDirs("src/main/kotlin")
    }

    defaultConfig {
        applicationId = "com.example.live_location_tracker"
        minSdk = 21  // Background location uchun minimal versiya
        targetSdk = 34
        versionCode = flutterVersionCode
        versionName = flutterVersionName
        multiDexEnabled = true
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        getByName("debug") {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isDebuggable = true
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Firebase BOM - barcha Firebase kutubxonalari uchun versiyani boshqaradi
    implementation(platform("com.google.firebase:firebase-bom:32.7.4"))
    
    // Firebase Analytics (ixtiyoriy)
    implementation("com.google.firebase:firebase-analytics-ktx")
    
    // Firebase Auth
    implementation("com.google.firebase:firebase-auth-ktx")
    
    // Cloud Firestore
    implementation("com.google.firebase:firebase-firestore-ktx")
    
    // Google Play services location
    implementation("com.google.android.gms:play-services-location:21.1.0")
    
    // Google Play services maps
    implementation("com.google.android.gms:play-services-maps:18.2.0")
    
    // Google Play services base (conflict'ni hal qilish uchun)
    implementation("com.google.android.gms:play-services-base:18.3.0")
    
    // Multidex support
    implementation("androidx.multidex:multidex:2.0.1")
}