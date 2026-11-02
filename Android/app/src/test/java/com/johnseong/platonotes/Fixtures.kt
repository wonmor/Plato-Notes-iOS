package com.johnseong.platonotes

import com.johnseong.platonotes.data.Note
import com.johnseong.platonotes.model.ExpiryDuration

/** The same sample notes as the iOS screenshot seed (title, text, duration, seconds left). */
object Fixtures {
    const val NOW = 1_793_000_000_000L   // a fixed clock

    fun notes(now: Long = NOW): List<Note> = listOf(
        Triple("Gate code for Friday", "4471, then the side door by the bike racks. Text Mira when you're in.", ExpiryDuration.OneHour) to 1260,
        Triple("Draft reply to Sam", "Thanks for the notes. I can do Thursday after 3, otherwise early next week.", ExpiryDuration.TwentyFourHours) to 61200,
        Triple("Wi-Fi for guests", "Network: Atrium 5G, password changes Monday.", ExpiryDuration.SevenDays) to 432000,
        Triple("Half-formed idea", "What if the reading list cleared itself every Sunday?", ExpiryDuration.ThreeDays) to 21600,
        Triple("Parking", "Level 3, row F, near the lift.", ExpiryDuration.FiveMinutes) to 140,
    ).mapIndexed { i, (t, left) ->
        val (title, content, d) = t
        Note(id = "n$i", title = title, content = content,
            createdAt = now - (d.seconds - left) * 1000L - i, expiresAt = now + left * 1000L, durationSeconds = d.seconds)
    }
}
