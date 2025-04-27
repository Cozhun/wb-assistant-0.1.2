allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Добавляем конфигурацию для исправления проблемы с namespace в плагинах
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.1.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.8.22")
    }
}

// Применяем фикс для всех подпроектов, включая плагины
subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            project.extensions.findByName("android")?.let { androidExt ->
                // Проверяем наличие поля namespace
                val hasNamespace = try {
                    androidExt.javaClass.methods.any { 
                        it.name == "getNamespace" || it.name == "namespace"
                    }
                } catch (e: Exception) {
                    false
                }
                
                if (!hasNamespace) {
                    // Пытаемся найти package в AndroidManifest.xml
                    val manifestFile = project.file("src/main/AndroidManifest.xml")
                    if (manifestFile.exists()) {
                        val manifestContent = manifestFile.readText()
                        val packageRegex = """package="([^"]+)"""".toRegex()
                        val matchResult = packageRegex.find(manifestContent)
                        if (matchResult != null) {
                            val packageName = matchResult.groupValues[1]
                            // Устанавливаем namespace из package
                            project.logger.lifecycle("Setting namespace for ${project.name} to $packageName")
                            androidExt.javaClass.methods.find { it.name == "setNamespace" }?.invoke(androidExt, packageName)
                        }
                    }
                }
            }
        }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
