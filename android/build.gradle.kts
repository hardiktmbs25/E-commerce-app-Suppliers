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
    // Only redirect build directory for subprojects that are within the main project root.
    // Plugins in the Pub cache should use their own default build directories to avoid cross-drive issues.
    val projectDir = project.projectDir.canonicalPath
    val rootDir = rootProject.rootDir.parentFile.canonicalPath
    if (projectDir.startsWith(rootDir)) {
        val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
        project.layout.buildDirectory.value(newSubprojectBuildDir)
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    val configureAndroid = {
        if (project.hasProperty("android")) {
            project.extensions.configure<com.android.build.gradle.BaseExtension>("android") {
                testOptions.unitTests.isIncludeAndroidResources = false
            }
        }
    }
    if (project.state.executed) {
        configureAndroid()
    } else {
        project.afterEvaluate { configureAndroid() }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
