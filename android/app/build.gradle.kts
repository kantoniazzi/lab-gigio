import java.util.Properties

// Chave de assinatura de release, lida de FORA do repositório
// (~/.gigio-keys/key.properties). Fica fora de propósito: perder essa chave
// significa nunca mais conseguir publicar atualização do app na Play Store,
// e commitá-la significa entregar a identidade do app a quem clonar o repo.
val keyProperties = Properties().apply {
    val file = File(System.getProperty("user.home"), ".gigio-keys/key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.antoniazi.gigio"
    // Fixado em 37 porque o flutter_secure_storage (usado para guardar o hash
    // do PIN do cuidador no Keystore) é compilado contra essa API. Manter o
    // padrão do Flutter faria o build falhar na fusão de dependências.
    // `compileSdk` só define contra qual API compilamos; `targetSdk` e
    // `minSdk` seguem o padrão do Flutter.
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.antoniazi.gigio"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keyProperties.getProperty("storeFile") != null) {
                storeFile = file(keyProperties.getProperty("storeFile"))
                storePassword = keyProperties.getProperty("storePassword")
                keyAlias = keyProperties.getProperty("keyAlias")
                keyPassword = keyProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Usa a chave de upload quando ela existe; cai para a de debug
            // apenas em máquinas sem a chave, para não travar `flutter run`.
            signingConfig = if (keyProperties.getProperty("storeFile") != null) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // O SDK Android do Datadog traz o WorkManager transitivamente, para agendar
    // o envio de dados em segundo plano — e junto vinha o Room 2.5.0, de 2023.
    //
    // Num aparelho com Android 16 e compileSdk 37, esse Room falha ao criar o
    // WorkDatabase e derruba o app ANTES da primeira tela:
    //
    //   Unable to get provider androidx.startup.InitializationProvider
    //   Caused by: Failed to create an instance of androidx.work.impl.WorkDatabase
    //
    // Num app de comunicação, isso significa a criança sem acesso à voz dela.
    // Declaramos as versões atuais aqui, explicitamente, para que fiquem
    // visíveis no arquivo do app em vez de escondidas na árvore de um terceiro.
    //
    // NÃO REMOVER sem testar a abertura num aparelho com Android recente.
    implementation("androidx.work:work-runtime:2.11.2")
    implementation("androidx.room:room-runtime:2.8.4")
}
