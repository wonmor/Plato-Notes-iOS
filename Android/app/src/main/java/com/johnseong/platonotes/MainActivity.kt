package com.johnseong.platonotes

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.SystemBarStyle
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.remember
import com.johnseong.platonotes.billing.TipJarBilling
import com.johnseong.platonotes.ui.AppHooks
import com.johnseong.platonotes.ui.AppearanceStore
import com.johnseong.platonotes.ui.PlatoNav
import com.johnseong.platonotes.ui.PlatoTheme
import com.johnseong.platonotes.ui.isDark

class MainActivity : ComponentActivity() {
    private val billing by lazy { TipJarBilling(this) }
    private var billingStarted = false

    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
        val app = application as PlatoApp
        val appearance = AppearanceStore(this)
        val hooks = AppHooks(
            tipJar = { billing.ui },
            startTipJar = { billingStarted = true; billing.start() },
            tip = { billing.tip(this, it) },
            retryTipJar = { billing.retry() },
            dismissTip = { billing.dismiss() },
            openUrl = { runCatching { startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(it))) } },
            version = "${BuildConfig.VERSION_NAME} (${BuildConfig.VERSION_CODE})",
        )
        setContent {
            val dark = appearance.value.isDark()
            // Status and navigation bar icons follow the app's own appearance, not only the system's.
            DisposableEffect(dark) {
                val style = if (dark) SystemBarStyle.dark(android.graphics.Color.TRANSPARENT)
                else SystemBarStyle.light(android.graphics.Color.TRANSPARENT, android.graphics.Color.TRANSPARENT)
                enableEdgeToEdge(statusBarStyle = style, navigationBarStyle = style)
                onDispose { }
            }
            PlatoTheme(dark) { PlatoNav(remember { app.repository }, appearance, hooks) }
        }
    }

    override fun onDestroy() {
        if (billingStarted) billing.close()
        super.onDestroy()
    }
}
