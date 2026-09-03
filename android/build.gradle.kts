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
    val proj = this
    plugins.withId("com.android.library") {
        val android = proj.extensions.findByName("android")
        if (android != null) {
            try {
                val getNamespace = android.javaClass.getMethod("getNamespace")
                val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                if (getNamespace.invoke(android) == null) {
                    val ns = if (proj.name == "ota_update") "sk.fourq.otaupdate" else "com.herflow.${proj.name.replace('-', '_')}"
                    setNamespace.invoke(android, ns)
                }
            } catch (_: Exception) {}
        }
        try {
            val manifestFile = file("${proj.projectDir}/src/main/AndroidManifest.xml")
            if (manifestFile.exists()) {
                val text = manifestFile.readText()
                if (text.contains("package=\"sk.fourq.otaupdate\"")) {
                    manifestFile.writeText(text.replace("package=\"sk.fourq.otaupdate\"", ""))
                }
            }
        } catch (_: Exception) {}
    }
    afterEvaluate {
        if (project.hasProperty("android")) {
            val android = project.extensions.findByName("android")
            if (android != null) {
                for (method in android.javaClass.methods) {
                    if (method.name == "setCompileSdkVersion" || method.name == "setCompileSdk" || method.name == "compileSdkVersion") {
                        try {
                            if (method.parameterCount == 1 && (method.parameterTypes[0] == Int::class.javaPrimitiveType || method.parameterTypes[0] == Integer::class.java)) {
                                method.invoke(android, 36)
                                break
                            }
                        } catch (_: Exception) {}
                    }
                }
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
