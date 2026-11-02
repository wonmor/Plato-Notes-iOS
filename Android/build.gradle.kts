// Same AGP / Kotlin line as the Orch-OR Android app, so the Gradle cache is shared.
plugins {
    id("com.android.application") version "8.13.0" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
    id("org.jetbrains.kotlin.plugin.compose") version "2.2.20" apply false
    id("com.google.devtools.ksp") version "2.2.20-2.0.4" apply false
    // Store screenshots: Roborazzi on Robolectric's native graphics (JVM, no emulator). 1.43.x runs on Java 17.
    id("io.github.takahirom.roborazzi") version "1.43.0" apply false
}
