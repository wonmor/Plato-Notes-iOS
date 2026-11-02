package com.johnseong.platonotes

import android.app.Application
import com.johnseong.platonotes.data.NoteRepository
import com.johnseong.platonotes.data.PlatoDatabase
import com.johnseong.platonotes.work.ExpiryWorker
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

class PlatoApp : Application() {
    val appScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

    val repository: NoteRepository by lazy {
        NoteRepository(PlatoDatabase.get(this).notes(), schedule = { ExpiryWorker.schedule(this, it) })
    }

    override fun onCreate() {
        super.onCreate()
        // Notes that ran out while the app was closed are deleted on launch, before anything shows them.
        appScope.launch { repository.purgeExpired() }
    }
}
