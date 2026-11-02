package com.johnseong.platonotes.model

import java.util.Locale

/**
 * The expiry rules, shared by the list, the detail view, the composer and the cleanup worker.
 * Pure Kotlin (times are epoch milliseconds) so it is unit-tested without Android.
 * Mirrors Note.swift / PlatoTheme.swift in the iOS app.
 */
enum class ExpiryDuration(val seconds: Int, val displayName: String, val shortName: String) {
    FiveMinutes(300, "5 minutes", "5m"),
    OneHour(3_600, "1 hour", "1h"),
    TwentyFourHours(86_400, "24 hours", "24h"),
    ThreeDays(259_200, "3 days", "3d"),
    SevenDays(604_800, "7 days", "7d");

    val millis: Long get() = seconds * 1000L

    companion object {
        val Default = TwentyFourHours
        fun fromSeconds(s: Int): ExpiryDuration = entries.firstOrNull { it.seconds == s } ?: Default
    }
}

/** Anything with a lifetime: the Room entity implements it, and tests use plain fakes. */
interface Expiring {
    val createdAt: Long
    val expiresAt: Long
    val durationSeconds: Int
}

/** Notes with less than this left go in "Vanishing soon". */
const val SOON_THRESHOLD_MS = 3_600_000L

/** How bright the ring is: the accent, then orange, then red. */
enum class LifeLevel { Healthy, Waning, Critical }

object Expiry {
    fun expiresAt(createdAt: Long, duration: ExpiryDuration): Long = createdAt + duration.millis

    fun isExpired(n: Expiring, now: Long): Boolean = now >= n.expiresAt

    fun remainingMs(n: Expiring, now: Long): Long = (n.expiresAt - now).coerceAtLeast(0)

    /** Fraction of the note's life left, 1 when written and 0 at expiry. */
    fun progress(n: Expiring, now: Long): Double {
        val total = n.durationSeconds * 1000.0
        if (total <= 0) return 0.0
        return (remainingMs(n, now) / total).coerceIn(0.0, 1.0)
    }

    fun level(progress: Double): LifeLevel = when {
        progress < 0.15 -> LifeLevel.Critical
        progress < 0.4 -> LifeLevel.Waning
        else -> LifeLevel.Healthy
    }

    /**
     * Text opacity: the note fades as its timer runs down, from 1 to 0.6. The theme's ink colours
     * are chosen so 0.6 still clears 4.5:1 on the card in both themes (see ContrastTest).
     */
    fun inkFade(progress: Double): Float = (0.6 + 0.4 * progress.coerceIn(0.0, 1.0)).toFloat()

    /** The preview line fades a little less far than the title's start, but never below the same floor. */
    fun previewFade(progress: Double): Float = (0.6 + 0.25 * progress.coerceIn(0.0, 1.0)).toFloat()

    /** A compact countdown: "4d 23h", "16:59:12", "37:55". */
    fun clock(remainingMs: Long): String {
        val r = (remainingMs.coerceAtLeast(0) / 1000).toInt()
        val d = r / 86_400
        val h = r % 86_400 / 3_600
        val m = r % 3_600 / 60
        val s = r % 60
        return when {
            d > 0 -> "${d}d ${h}h"
            h > 0 -> String.format(Locale.US, "%d:%02d:%02d", h, m, s)
            else -> String.format(Locale.US, "%d:%02d", m, s)
        }
    }

    /** Spoken/long form for accessibility: "4d 23h remaining". */
    fun remainingSpoken(remainingMs: Long): String {
        val r = (remainingMs.coerceAtLeast(0) / 1000).toInt()
        if (r <= 0) return "Expired"
        val d = r / 86_400
        val h = r % 86_400 / 3_600
        val m = r % 3_600 / 60
        val s = r % 60
        return when {
            d > 0 -> "${d}d ${h}h remaining"
            h > 0 -> "${h}h ${m}m remaining"
            m > 0 -> "${m}m ${s}s remaining"
            else -> "${s}s remaining"
        }
    }

    /** The list's two sections. Expired notes are dropped; "soon" is soonest first, "later" newest first. */
    fun <T : Expiring> sections(notes: List<T>, now: Long): Pair<List<T>, List<T>> {
        val active = notes.filter { !isExpired(it, now) }
        val soon = active.filter { remainingMs(it, now) < SOON_THRESHOLD_MS }.sortedBy { it.expiresAt }
        val later = active.filter { remainingMs(it, now) >= SOON_THRESHOLD_MS }.sortedByDescending { it.createdAt }
        return soon to later
    }

    /** When the cleanup worker should next wake, or null when nothing is left to expire. */
    fun nextWake(notes: List<Expiring>, now: Long): Long? =
        notes.filter { !isExpired(it, now) }.minOfOrNull { it.expiresAt }

    fun countLabel(n: Int): String = when (n) {
        0 -> "No notes"
        1 -> "1 note"
        else -> "$n notes"
    }
}
