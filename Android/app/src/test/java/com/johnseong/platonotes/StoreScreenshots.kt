package com.johnseong.platonotes

import androidx.compose.runtime.Composable
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onRoot
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.github.takahirom.roborazzi.captureRoboImage
import com.johnseong.platonotes.billing.TipJarUi
import com.johnseong.platonotes.billing.TipStatus
import com.johnseong.platonotes.ui.Appearance
import com.johnseong.platonotes.ui.ComposeScreen
import com.johnseong.platonotes.ui.DetailScreen
import com.johnseong.platonotes.ui.NotesScreen
import com.johnseong.platonotes.ui.PlatoTheme
import com.johnseong.platonotes.ui.SettingsScreen
import com.johnseong.platonotes.ui.TipJarContent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.ui.Modifier
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode

/**
 * Play Store screenshots, rendered on the JVM (Robolectric native graphics + Roborazzi) from the real
 * composables with the iOS screenshot notes and a fixed clock. No emulator, no status bar.
 *   ./gradlew :app:testDebugUnitTest --tests '*StoreScreenshots*' -Proborazzi.test.record=true
 * Output: app/build/outputs/roborazzi/<device>-<n>-<screen>.png
 */
@RunWith(AndroidJUnit4::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
abstract class StoreScreenshots(private val device: String) {
    @get:Rule val rule = createComposeRule()

    private fun shot(name: String, dark: Boolean = false, content: @Composable () -> Unit) {
        rule.setContent { PlatoTheme(dark) { content() } }
        rule.waitForIdle()
        rule.onRoot().captureRoboImage("build/outputs/roborazzi/$device-$name.png")
    }

    private val notes = Fixtures.notes()
    private val now = Fixtures.NOW

    @Test fun s1_list() = shot("1-list") { NotesScreen(notes, now, {}, {}, {}, {}) }
    @Test fun s2_detail() = shot("2-detail") {
        DetailScreen(notes.first { it.title == "Gate code for Friday" }, now, {}, { _, _ -> }, {})
    }
    @Test fun s3_compose() = shot("3-compose") {
        ComposeScreen(now, {}, { _, _, _ -> }, "Pick up from the cleaners", "Ticket 2219. They close at 6 on Saturdays.")
    }
    @Test fun s4_dark() = shot("4-list-dark", dark = true) { NotesScreen(notes, now, {}, {}, {}, {}) }
    @Test fun s5_settings() = shot("5-settings") { SettingsScreen(Appearance.Light, {}, "1.1 (1)", {}, {}, {}) }
    @Test fun s6_empty() = shot("6-empty") { NotesScreen(emptyList(), now, {}, {}, {}, {}) }
    @Test fun t1_tipjar() = shot("tipjar") {
        Box(Modifier.fillMaxSize().background(MaterialTheme.colorScheme.background)) { TipJarContent(TipJarUi.preview(), {}, {}, {}) }
    }
    @Test fun t2_thanks() = shot("tipjar-thanks") {
        Box(Modifier.fillMaxSize().background(MaterialTheme.colorScheme.background)) { TipJarContent(TipJarUi.preview(TipStatus.Thanked), {}, {}, {}) }
    }
}

// Phone 1080 x 2160 (2:1, Play's limit); 7" tablet 1920 x 1200; 10" tablet 2560 x 1600.
@Config(qualifiers = "w360dp-h720dp-xxhdpi") class PhoneScreenshots : StoreScreenshots("phone")
@Config(qualifiers = "w960dp-h600dp-land-xhdpi") class Tablet7Screenshots : StoreScreenshots("tablet7")
@Config(qualifiers = "w1280dp-h800dp-land-xhdpi") class Tablet10Screenshots : StoreScreenshots("tablet10")
