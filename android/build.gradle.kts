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
    // Hook into plugin application (fires BEFORE evaluation completes,
    // so the namespace is set before AGP creates variant builders).
    project.pluginManager.withPlugin("com.android.library") {
        val android = project.extensions.getByName("android")
                as com.android.build.gradle.LibraryExtension
        if (android.namespace.isNullOrEmpty()) {
            android.namespace = "com.luxe.studio.${project.name.replace("-", "_")}"
            println("Auto-set namespace for ${project.name}")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
