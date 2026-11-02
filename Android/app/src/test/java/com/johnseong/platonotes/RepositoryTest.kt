package com.johnseong.platonotes

import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.johnseong.platonotes.data.NoteRepository
import com.johnseong.platonotes.data.PlatoDatabase
import com.johnseong.platonotes.model.ExpiryDuration
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith

/** Room (in memory) plus the re-arming of the cleanup job. */
@RunWith(AndroidJUnit4::class)
class RepositoryTest {
    private val db = Room.inMemoryDatabaseBuilder(ApplicationProvider.getApplicationContext(), PlatoDatabase::class.java)
        .allowMainThreadQueries().build()
    private var now = Fixtures.NOW
    private val armed = mutableListOf<Long?>()
    private val repo = NoteRepository(db.notes(), schedule = { armed += it }, clock = { now })

    @After fun close() = db.close()

    @Test fun createArmsForSoonestAndPurgeDeletesOnlyExpired() = runTest {
        val long = repo.create("  Long  ", "x", ExpiryDuration.SevenDays)
        assertEquals("Long", long.title)
        val short = repo.create("Short", "", ExpiryDuration.FiveMinutes)
        assertEquals(short.expiresAt, armed.last())

        now = short.expiresAt                     // the short note's time is up
        assertEquals(1, repo.purgeExpired())
        assertEquals(listOf(long.id), repo.notes.first().map { it.id })
        assertEquals(long.expiresAt, armed.last())

        repo.burn(long.id)
        assertEquals(0, repo.notes.first().size)
        assertEquals(null, armed.last())          // nothing left: the job is cancelled
    }

    @Test fun editKeepsExpiry() = runTest {
        val n = repo.create("A", "b", ExpiryDuration.OneHour)
        repo.edit(n, "A2", "b2")
        val stored = repo.notes.first().single()
        assertEquals("A2", stored.title)
        assertEquals(n.expiresAt, stored.expiresAt)
    }
}
