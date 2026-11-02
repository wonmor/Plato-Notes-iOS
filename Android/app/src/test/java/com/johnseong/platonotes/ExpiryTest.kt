package com.johnseong.platonotes

import com.johnseong.platonotes.model.Expiring
import com.johnseong.platonotes.model.Expiry
import com.johnseong.platonotes.model.ExpiryDuration
import com.johnseong.platonotes.model.LifeLevel
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class ExpiryTest {
    private data class N(val name: String, override val createdAt: Long, override val expiresAt: Long, override val durationSeconds: Int) : Expiring
    private fun n(name: String, d: ExpiryDuration, created: Long) = N(name, created, Expiry.expiresAt(created, d), d.seconds)
    private val t0 = 1_800_000_000_000L

    @Test fun durationsMatchIos() {
        assertEquals(listOf(300, 3600, 86400, 259200, 604800), ExpiryDuration.entries.map { it.seconds })
        assertEquals(listOf("5m", "1h", "24h", "3d", "7d"), ExpiryDuration.entries.map { it.shortName })
        assertEquals(ExpiryDuration.TwentyFourHours, ExpiryDuration.Default)
        assertEquals(ExpiryDuration.Default, ExpiryDuration.fromSeconds(42))
    }

    @Test fun expiresExactlyAtDeadline() {
        val note = n("a", ExpiryDuration.FiveMinutes, t0)
        assertEquals(t0 + 300_000, note.expiresAt)
        assertFalse(Expiry.isExpired(note, t0 + 299_999))
        assertTrue(Expiry.isExpired(note, t0 + 300_000))
        assertEquals(0, Expiry.remainingMs(note, t0 + 400_000))
    }

    @Test fun progressDrainsAndClamps() {
        val note = n("a", ExpiryDuration.OneHour, t0)
        assertEquals(1.0, Expiry.progress(note, t0), 1e-9)
        assertEquals(0.5, Expiry.progress(note, t0 + 1_800_000), 1e-9)
        assertEquals(0.0, Expiry.progress(note, t0 + 9_999_999), 1e-9)
        assertEquals(1.0, Expiry.progress(note, t0 - 5_000), 1e-9)
    }

    @Test fun ringLevels() {
        assertEquals(LifeLevel.Healthy, Expiry.level(0.4))
        assertEquals(LifeLevel.Waning, Expiry.level(0.39))
        assertEquals(LifeLevel.Waning, Expiry.level(0.15))
        assertEquals(LifeLevel.Critical, Expiry.level(0.149))
    }

    @Test fun fadeNeverBelowFloor() {
        assertEquals(1f, Expiry.inkFade(1.0), 1e-6f)
        assertEquals(0.6f, Expiry.inkFade(0.0), 1e-6f)
        assertEquals(0.6f, Expiry.inkFade(-3.0), 1e-6f)
        assertEquals(0.6f, Expiry.previewFade(0.0), 1e-6f)
    }

    @Test fun clockFormats() {
        assertEquals("4d 23h", Expiry.clock((4 * 86400 + 23 * 3600 + 59) * 1000L))
        assertEquals("16:59:12", Expiry.clock((16 * 3600 + 59 * 60 + 12) * 1000L))
        assertEquals("37:55", Expiry.clock((37 * 60 + 55) * 1000L))
        assertEquals("0:00", Expiry.clock(-5))
        assertEquals("2m 20s remaining", Expiry.remainingSpoken(140_000))
        assertEquals("Expired", Expiry.remainingSpoken(0))
    }

    @Test fun sectionsSplitAtOneHour() {
        val now = t0 + 10_000_000
        val soonLate = N("soon-late", t0, now + 3_000_000, 3600)
        val soonFirst = N("soon-first", t0 + 1, now + 140_000, 300)
        val boundary = N("boundary", t0 + 2, now + 3_600_000, 86400)
        val newest = N("newest", t0 + 5, now + 400_000_000, 604800)
        val gone = N("gone", t0 + 6, now, 300)
        val (soon, later) = Expiry.sections(listOf(soonLate, soonFirst, boundary, newest, gone), now)
        assertEquals(listOf("soon-first", "soon-late"), soon.map { it.name })
        assertEquals(listOf("newest", "boundary"), later.map { it.name })
    }

    @Test fun nextWakeIsSoonestLiveExpiry() {
        val a = n("a", ExpiryDuration.OneHour, t0)
        val b = n("b", ExpiryDuration.FiveMinutes, t0)
        assertEquals(b.expiresAt, Expiry.nextWake(listOf(a, b), t0))
        assertEquals(a.expiresAt, Expiry.nextWake(listOf(a, b), b.expiresAt))
        assertNull(Expiry.nextWake(listOf(a, b), a.expiresAt))
    }

    @Test fun countLabel() {
        assertEquals("No notes", Expiry.countLabel(0))
        assertEquals("1 note", Expiry.countLabel(1))
        assertEquals("5 notes", Expiry.countLabel(5))
    }
}
