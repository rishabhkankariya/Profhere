// This file is required for the root directory to be recognized as a Gradle project.
// The actual build logic is located in the 'android' directory.
tasks.register("clean", Delete::class) {
    delete(rootProject.layout.buildDirectory)
}
