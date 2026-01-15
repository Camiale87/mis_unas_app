pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    // SUBIMOS A 8.9.1 COMO PIDE EL ERROR
    id("com.android.application") version "8.9.1" apply false 
    // SUBIMOS KOTLIN A 2.1.0 PARA QUE NO TE SALGA EL AVISO NARANJA
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
    // MANTENEMOS GOOGLE SERVICES
    id("com.google.gms.google-services") version "4.4.1" apply false
}

include(":app")