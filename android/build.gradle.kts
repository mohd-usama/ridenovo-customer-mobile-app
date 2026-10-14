allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    val configureAndroid: Project.() -> Unit = {
        val android = extensions.findByType(com.android.build.gradle.BaseExtension::class.java)
        if (android != null) {
            val currentSdk = android.compileSdkVersion
            val sdkVersion = currentSdk?.removePrefix("android-`")?.removePrefix("android-")?.toIntOrNull() ?: 0
            if (sdkVersion < 34) {
                android.compileSdkVersion(34)
            }
        }
    }

    if (state.executed) {
        configureAndroid()
    } else {
        afterEvaluate {
            configureAndroid()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
