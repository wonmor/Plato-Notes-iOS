package com.johnseong.platonotes.data

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase

@Database(entities = [Note::class], version = 1, exportSchema = true)
abstract class PlatoDatabase : RoomDatabase() {
    abstract fun notes(): NoteDao

    companion object {
        @Volatile private var instance: PlatoDatabase? = null

        fun get(context: Context): PlatoDatabase = instance ?: synchronized(this) {
            instance ?: Room.databaseBuilder(context.applicationContext, PlatoDatabase::class.java, "plato.db")
                .build().also { instance = it }
        }
    }
}
