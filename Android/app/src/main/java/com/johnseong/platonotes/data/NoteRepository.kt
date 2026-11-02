package com.johnseong.platonotes.data

import com.johnseong.platonotes.model.ExpiryDuration
import kotlinx.coroutines.flow.Flow

/**
 * The only way notes change. Every write re-arms the cleanup so an expired note is deleted even when the
 * app is closed. [schedule] receives the next expiry time (or null when there is nothing left).
 */
class NoteRepository(
    private val dao: NoteDao,
    private val schedule: (nextExpiry: Long?) -> Unit,
    private val clock: () -> Long = System::currentTimeMillis,
) {
    val notes: Flow<List<Note>> = dao.observeAll()

    fun note(id: String): Flow<Note?> = dao.observe(id)

    suspend fun create(title: String, content: String, duration: ExpiryDuration): Note {
        val note = Note.create(title.trim(), content.trim(), duration, clock())
        dao.insert(note)
        rearm()
        return note
    }

    suspend fun edit(note: Note, title: String, content: String) {
        if (note.expiresAt <= clock()) return
        dao.update(note.copy(title = title, content = content))
    }

    suspend fun burn(id: String) {
        dao.delete(id)
        rearm()
    }

    /** Deletes what has expired and schedules the next wake-up. Returns how many notes were deleted. */
    suspend fun purgeExpired(): Int {
        val gone = dao.deleteExpired(clock())
        rearm()
        return gone
    }

    private suspend fun rearm() = schedule(dao.nextExpiry(clock()))
}
