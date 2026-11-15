// Módulo de la app "Ciclo de vida".
// AGP 9 trae Kotlin integrado: no hace falta el plugin org.jetbrains.kotlin.android.
plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.compose)
}

android {
    namespace = "com.demo.ciclovida"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.demo.ciclovida"
        minSdk = 26
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        compose = true
    }
}

dependencies {
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.activity.compose)
    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.compose.ui)
    implementation(libs.androidx.compose.material3)
    // viewModel() para obtener el ContadorViewModel desde Compose.
    implementation(libs.androidx.lifecycle.viewmodel.compose)
    // Integración del ciclo de vida con Compose.
    implementation(libs.androidx.lifecycle.runtime.compose)
}
