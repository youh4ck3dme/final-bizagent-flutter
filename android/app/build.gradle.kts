import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.firebase-perf")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load local properties for Flutter configuration
val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localProperties.load(FileInputStream(localPropertiesFile))
}

val flutterVersionCode = localProperties.getProperty("flutter.versionCode") ?: "3"
val flutterVersionName = localProperties.getProperty("flutter.versionName") ?: "1.0.2"

android {
    namespace = "com.bizagent.app"
    compileSdk = 34
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
    }

    defaultConfig {
        applicationId = "com.bizagent.app"
        minSdk = 24
        targetSdk = 34
        versionCode = flutterVersionCode.toInt()
        versionName = flutterVersionName
        
        multiDexEnabled = true
        
        // Locale configuration
        resourceConfigurations.addAll(listOf("sk", "cs", "en"))
        
        // Ndk filters
        ndk {
            abiFilters.addAll(listOf("armeabi-v7a", "arm64-v8a", "x86_64"))
        }
    }

    signingConfigs {
        create("release") {
            val keystorePropertiesFile = rootProject.file("key.properties")
            val keystoreProperties = Properties()
            if (keystorePropertiesFile.exists()) {
                keystoreProperties.load(FileInputStream(keystorePropertiesFile))
                keyAlias = keystoreProperties["keyAlias"] as? String
                keyPassword = keystoreProperties["keyPassword"] as? String
                storeFile = keystoreProperties["storeFile"]?.let { file(it as String) }
                storePassword = keystoreProperties["storePassword"] as? String
            }
        }
    }

    buildTypes {
        getByName("debug") {
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
            isDebuggable = true
            isMinifyEnabled = false
            
            buildConfigField("String", "APP_NAME", "\"BizAgent Debug\"")
            buildConfigField("boolean", "DEBUG_MODE", "true")
        }
        
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            
            // Minification & Obfuscation
            isMinifyEnabled = true
            isShrinkResources = true
            isDebuggable = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            
            // Native debug symbols
            ndk {
                debugSymbolLevel = "FULL"
            }
            
            // Build config fields
            buildConfigField("String", "APP_NAME", "\"BizAgent\"")
            buildConfigField("boolean", "DEBUG_MODE", "false")

            // Enable native symbol upload for Crashlytics
            configure<com.google.firebase.crashlytics.buildtools.gradle.CrashlyticsExtension> {
                nativeSymbolUploadEnabled = true
            }
        }
        
        create("profile") {
            initWith(getByName("debug"))
            applicationIdSuffix = ".profile"
            versionNameSuffix = "-profile"
        }
    }

    flavorDimensions += "environment"
    productFlavors {
        create("production") {
            dimension = "environment"
            manifestPlaceholders["appName"] = "BizAgent"
        }
        
        create("staging") {
            dimension = "environment"
            applicationIdSuffix = ".staging"
            versionNameSuffix = "-staging"
            manifestPlaceholders["appName"] = "BizAgent Staging"
        }
    }

    // Lint options
    lint {
        disable += "InvalidPackage"
        checkReleaseBuilds = true
        abortOnError = false
    }

    // Packaging options
    packaging {
        resources {
            excludes += listOf(
                "META-INF/DEPENDENCIES",
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt",
                "META-INF/NOTICE",
                "META-INF/NOTICE.txt"
            )
        }
        jniLibs {
            // Keep debug symbols in the native libraries to allow Play Store to de-obfuscate crashes
            keepDebugSymbols.add("**/*.so")
        }
    }
    
    buildFeatures {
        buildConfig = true
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    
    // Kotlin
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8:2.2.20")
    
    // Firebase BOM (Bill of Materials)
    implementation(platform("com.google.firebase:firebase-bom:32.7.4"))
    implementation("com.google.firebase:firebase-analytics-ktx")
    implementation("com.google.firebase:firebase-crashlytics-ktx")
    implementation("com.google.firebase:firebase-perf-ktx")
    implementation("com.google.firebase:firebase-messaging-ktx")
    implementation("com.google.firebase:firebase-config-ktx")
    
    // MultiDex
    implementation("androidx.multidex:multidex:2.0.1")
    
    // Work Manager (for background tasks)
    implementation("androidx.work:work-runtime-ktx:2.9.0")
}
