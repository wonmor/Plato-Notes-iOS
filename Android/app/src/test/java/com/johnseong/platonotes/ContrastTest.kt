package com.johnseong.platonotes

import com.johnseong.platonotes.model.Expiry
import com.johnseong.platonotes.ui.Palette
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.math.pow

/** Faded note text, secondary text and the accent stay at 4.5:1 or better on the card, in both themes. */
class ContrastTest {
    private fun ch(c: Long, shift: Int) = ((c shr shift) and 0xFF) / 255.0
    private fun lin(v: Double) = if (v <= 0.03928) v / 12.92 else ((v + 0.055) / 1.055).pow(2.4)
    private fun lum(c: Long) = 0.2126 * lin(ch(c, 16)) + 0.7152 * lin(ch(c, 8)) + 0.0722 * lin(ch(c, 0))
    private fun blend(fg: Long, bg: Long, a: Double): Long {
        fun mix(s: Int) = (ch(fg, s) * a + ch(bg, s) * (1 - a)).times(255).toLong()
        return (0xFFL shl 24) or (mix(16) shl 16) or (mix(8) shl 8) or mix(0)
    }
    private fun ratio(a: Long, b: Long): Double { val x = lum(a); val y = lum(b); return (maxOf(x, y) + 0.05) / (minOf(x, y) + 0.05) }

    @Test fun lightTheme() = check(Palette.InkLight, Palette.InkSecondaryLight, Palette.AccentLight, Palette.RedLight, Palette.CardLight)
    @Test fun darkTheme() = check(Palette.InkDark, Palette.InkSecondaryDark, Palette.AccentDark, Palette.RedDark, Palette.CardDark)

    private fun check(ink: Long, secondary: Long, accent: Long, red: Long, card: Long) {
        val faded = blend(ink, card, Expiry.inkFade(0.0).toDouble())
        val preview = blend(ink, card, Expiry.previewFade(0.0).toDouble())
        mapOf("faded title" to faded, "faded preview" to preview, "secondary" to secondary, "accent" to accent, "red clock" to red)
            .forEach { (name, c) -> val r = ratio(c, card); assertTrue("$name is ${"%.2f".format(r)}:1", r >= 4.5) }
    }
}
