// This file allows Gradle to recognize the android folder as a subproject
// when syncing from the root directory.
rootProject.name = "Profhere"
include(":android")
project(":android").projectDir = file("android")
