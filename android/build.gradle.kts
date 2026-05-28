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
    // 1. Kode kita untuk memaksa SDK 36 diletakkan di sini
    afterEvaluate {
        val androidExt = extensions.findByName("android")
        if (androidExt != null) {
            (androidExt as com.android.build.gradle.BaseExtension).compileSdkVersion(36)
        }
    }

    // 2. Kode bawaan Flutter (HARUS berada di bawah afterEvaluate)
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}