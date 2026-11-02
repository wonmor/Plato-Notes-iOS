package com.johnseong.platonotes.data

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Query
import androidx.room.Update
import kotlinx.coroutines.flow.Flow

@Dao
interface NoteDao {
    @Query("SELECT * FROM notes ORDER BY createdAt DESC")
    fun observeAll(): Flow<List<Note>>

    @Query("SELECT * FROM notes WHERE id = :id")
    fun observe(id: String): Flow<Note?>

    @Insert
    suspend fun insert(note: Note)

    @Update
    suspend fun update(note: Note)

    @Query("DELETE FROM notes WHERE id = :id")
    suspend fun delete(id: String)

    /** Deletes every note whose time is up; returns how many went. */
    @Query("DELETE FROM notes WHERE expiresAt <= :now")
    suspend fun deleteExpired(now: Long): Int

    @Query("SELECT MIN(expiresAt) FROM notes WHERE expiresAt > :now")
    suspend fun nextExpiry(now: Long): Long?
}
