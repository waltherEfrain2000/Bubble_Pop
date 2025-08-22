import java.util.Properties
import java.io.FileInputStream

// Lee las propiedades del keystore
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// Función helper para obtener propiedades del keystore de forma segura
fun getKeystoreProperty(key: String): String? {
    return keystoreProperties.getProperty(key)
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {

    namespace = "com.walther.bubblepop"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.walther.bubblepop"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias") ?: "wally"
            keyPassword = keystoreProperties.getProperty("keyPassword") ?: "Manchester2000"
            storeFile = rootProject.file(keystoreProperties.getProperty("storeFile") ?: "keystore.jks")
            storePassword = keystoreProperties.getProperty("storePassword") ?: "Manchester2000"
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            // Puedes agregar opciones adicionales aquí si lo necesitas.
        }
    }
}

flutter {
    source = "../.."
}