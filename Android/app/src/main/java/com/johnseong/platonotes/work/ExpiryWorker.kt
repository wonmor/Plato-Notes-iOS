package com.johnseong.platonotes.work

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import com.johnseong.platonotes.PlatoApp
import java.util.concurrent.TimeUnit

/**
 * Deletes expired notes while the app is closed. One unique one-off job is kept armed for the next
 * expiry; each run deletes what is due and re-arms for the following note. The app also purges on
 * launch and every second while open, so the worker only matters when Plato is not running.
 */
class ExpiryWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {
    override suspend fun doWork(): Result {
        (applicationContext as PlatoApp).repository.purgeExpired()
        return Result.success()
    }

    companion object {
        const val NAME = "plato-expiry"

        fun schedule(context: Context, nextExpiry: Long?, now: Long = System.currentTimeMillis()) {
            val wm = WorkManager.getInstance(context)
            if (nextExpiry == null) {
                wm.cancelUniqueWork(NAME)
                return
            }
            val req = OneTimeWorkRequestBuilder<ExpiryWorker>()
                .setInitialDelay((nextExpiry - now).coerceAtLeast(0), TimeUnit.MILLISECONDS)
                .build()
            wm.enqueueUniqueWork(NAME, ExistingWorkPolicy.REPLACE, req)
        }
    }
}
