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
    afterEvaluate {
        if (project.hasProperty("android")) {
            val android = project.extensions.findByName("android") ?: return@afterEvaluate
            try {
                val methods = android.javaClass.methods
                
                // 1. Set Namespace if missing or if it's the problematic package
                val getNamespace = methods.find { it.name == "getNamespace" && it.parameterCount == 0 }
                val setNamespace = methods.find { it.name == "setNamespace" && it.parameterCount == 1 && it.parameterTypes[0] == String::class.java }
                
                var currentNamespace = getNamespace?.invoke(android)
                
                // Explicit fix for image_gallery_saver
                if (project.name == "image_gallery_saver") {
                     val fixedNamespace = "com.example.image_gallery_saver"
                     setNamespace?.invoke(android, fixedNamespace)
                     println("Force-set namespace for ${project.name} to $fixedNamespace")
                } else if (currentNamespace == null || (currentNamespace is String && currentNamespace.isEmpty())) {
                    val defaultNamespace = "com.luxe.studio." + project.name.replace("-", "_")
                    setNamespace?.invoke(android, defaultNamespace)
                    println("Auto-set namespace for ${project.name} to $defaultNamespace")
                }

                // 2. Ensure sane SDK versions for AGP 8 compatibility
                val setCompileSdk = methods.find { (it.name == "setCompileSdk" || it.name == "compileSdkVersion") && it.parameterCount == 1 }
                // Try setCompileSdk(Integer) first
                try {
                    setCompileSdk?.invoke(android, 34)
                } catch (e: Exception) {
                    // fallback or ignore
                }

                // 3. Fix potential buildToolsVersion issues
                val setBuildTools = methods.find { (it.name == "setBuildToolsVersion" || it.name == "buildToolsVersion") && it.parameterCount == 1 }
                try {
                    setBuildTools?.invoke(android, "34.0.0")
                } catch (e: Exception) {
                }
                
                println("Stabilized project: ${project.name}")
            } catch (e: Exception) {
                // Ignore if reflection fails
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
