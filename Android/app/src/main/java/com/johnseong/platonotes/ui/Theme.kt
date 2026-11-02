package com.johnseong.platonotes.ui

import android.content.Context
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Typography
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color
import com.johnseong.platonotes.model.LifeLevel

/**
 * Plato on Android: Material 3 with the system font, grouped cards on a warm neutral ground, and the
 * iOS app's two signatures, a warm sienna accent (from the wax tablet in the icon) and the fading
 * countdown: a ring that drains and note text that fades as time runs out.
 *
 * Accent contrast: #B4441C on white 5.6:1; #FF8A5C on the dark card 7.0:1 (checked in ContrastTest).
 */
object Palette {
    // Light
    const val AccentLight = 0xFFB4441C
    const val GroundLight = 0xFFF3F0ED
    const val CardLight = 0xFFFFFFFF
    const val InkLight = 0xFF121110
    const val InkSecondaryLight = 0xFF5C5551
    const val OrangeLight = 0xFFC75A0A
    const val RedLight = 0xFFC62828
    const val TrackLight = 0xFFE9E3DF
    const val OutlineLight = 0xFFDCD5D0

    // Dark
    const val AccentDark = 0xFFFF8A5C
    const val GroundDark = 0xFF121110
    const val CardDark = 0xFF221F1E
    const val InkDark = 0xFFF0EBE8
    const val InkSecondaryDark = 0xFFB8AFAA
    const val OrangeDark = 0xFFFFA34F
    const val RedDark = 0xFFFF7A70
    const val TrackDark = 0xFF3A3533
    const val OutlineDark = 0xFF3F3936
}

@Immutable
data class LifeColors(val healthy: Color, val waning: Color, val critical: Color, val track: Color) {
    fun of(level: LifeLevel) = when (level) {
        LifeLevel.Healthy -> healthy
        LifeLevel.Waning -> waning
        LifeLevel.Critical -> critical
    }
}

val LocalLifeColors = staticCompositionLocalOf {
    LifeColors(Color(Palette.AccentLight), Color(Palette.OrangeLight), Color(Palette.RedLight), Color(Palette.TrackLight))
}

private val LightScheme = lightColorScheme(
    primary = Color(Palette.AccentLight),
    onPrimary = Color.White,
    primaryContainer = Color(0xFFFFDBCD),
    onPrimaryContainer = Color(0xFF3A0B00),
    secondaryContainer = Color(0xFFF7DED4),
    onSecondaryContainer = Color(0xFF2C150D),
    background = Color(Palette.GroundLight),
    onBackground = Color(Palette.InkLight),
    surface = Color(Palette.GroundLight),
    onSurface = Color(Palette.InkLight),
    onSurfaceVariant = Color(Palette.InkSecondaryLight),
    surfaceContainerLowest = Color(Palette.CardLight),
    surfaceContainerLow = Color(0xFFF8F5F3),
    surfaceContainer = Color(Palette.GroundLight),
    surfaceContainerHigh = Color(0xFFEDE9E6),
    surfaceContainerHighest = Color(0xFFE7E2DF),
    outline = Color(0xFF857D78),
    outlineVariant = Color(Palette.OutlineLight),
    error = Color(Palette.RedLight),
    onError = Color.White,
)

private val DarkScheme = darkColorScheme(
    primary = Color(Palette.AccentDark),
    onPrimary = Color(0xFF3A1100),
    primaryContainer = Color(0xFF6E2A10),
    onPrimaryContainer = Color(0xFFFFDBCD),
    secondaryContainer = Color(0xFF4A3129),
    onSecondaryContainer = Color(0xFFF7DED4),
    background = Color(Palette.GroundDark),
    onBackground = Color(Palette.InkDark),
    surface = Color(Palette.GroundDark),
    onSurface = Color(Palette.InkDark),
    onSurfaceVariant = Color(Palette.InkSecondaryDark),
    surfaceContainerLowest = Color(Palette.CardDark),
    surfaceContainerLow = Color(0xFF1A1817),
    surfaceContainer = Color(Palette.GroundDark),
    surfaceContainerHigh = Color(0xFF2A2726),
    surfaceContainerHighest = Color(0xFF353130),
    outline = Color(0xFF9C928D),
    outlineVariant = Color(Palette.OutlineDark),
    error = Color(Palette.RedDark),
    onError = Color(0xFF410002),
)

/** Light is the default, as on iOS. */
enum class Appearance(val title: String) { Light("Light"), Dark("Dark"), System("System") }

/** The appearance choice, kept in SharedPreferences under the same key name as iOS ("appearance"). */
class AppearanceStore(context: Context?) {
    private val prefs = context?.getSharedPreferences("plato", Context.MODE_PRIVATE)
    var value by mutableStateOf(
        prefs?.getString(KEY, null)?.let { s -> Appearance.entries.firstOrNull { it.name.equals(s, true) } } ?: Appearance.Light
    )
        private set

    fun set(a: Appearance) {
        value = a
        prefs?.edit()?.putString(KEY, a.name.lowercase())?.apply()
    }

    companion object { const val KEY = "appearance" }
}

@Composable
fun Appearance.isDark(): Boolean = when (this) {
    Appearance.Light -> false
    Appearance.Dark -> true
    Appearance.System -> isSystemInDarkTheme()
}

@Composable
fun PlatoTheme(dark: Boolean, content: @Composable () -> Unit) {
    val life = if (dark) LifeColors(Color(Palette.AccentDark), Color(Palette.OrangeDark), Color(Palette.RedDark), Color(Palette.TrackDark))
    else LifeColors(Color(Palette.AccentLight), Color(Palette.OrangeLight), Color(Palette.RedLight), Color(Palette.TrackLight))
    CompositionLocalProvider(LocalLifeColors provides life) {
        // Typography stays the Material default, which is the system font (Roboto / Google Sans on Pixels).
        MaterialTheme(colorScheme = if (dark) DarkScheme else LightScheme, typography = Typography(), content = content)
    }
}
