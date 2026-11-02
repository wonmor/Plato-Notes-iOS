package com.johnseong.platonotes.data

import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey
import com.johnseong.platonotes.model.Expiring
import com.johnseong.platonotes.model.Expiry
import com.johnseong.platonotes.model.ExpiryDuration
import java.util.UUID

@Entity(tableName = "notes", indices = [Index("expiresAt")])
data class Note(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val title: String = "",
    val content: String = "",
    override val createdAt: Long,
    override val expiresAt: Long,
    override val durationSeconds: Int,
) : Expiring {
    val duration: ExpiryDuration get() = ExpiryDuration.fromSeconds(durationSeconds)

    companion object {
        fun create(title: String, content: String, duration: ExpiryDuration, now: Long = System.currentTimeMillis()) =
            Note(title = title, content = content, createdAt = now,
                expiresAt = Expiry.expiresAt(now, duration), durationSeconds = duration.seconds)
    }
}
