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
    afterEvaluate { project ->
        if (project.hasProperty("android")) {
            val android = project.extensions.findByName("android")
            if (android != null) {
                try {
                    val namespaceMethod = android.javaClass.getMethod("setNamespace", String::class.java)
                    val getNamespaceMethod = android.javaClass.getMethod("getNamespace")
                    
                    var namespace = getNamespaceMethod.invoke(android) as String?
                    
                    // Fix for image_gallery_saver
                    if (project.name == "image_gallery_saver") {
                        namespaceMethod.invoke(android, "com.example.image_gallery_saver")
                        println("Force-set namespace for ${project.name}")
                    } else if (namespace == null || namespace.isEmpty()) {
                        val defaultNamespace = "com.luxe.studio.${project.name.replace("-", "_")}"
                        namespaceMethod.invoke(android, defaultNamespace)
                        println("Auto-set namespace for ${project.name} to $defaultNamespace")
                    }
                } catch (e: Exception) {
                    println("Namespace fix failed for ${project.name}: ${e.message}")
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
