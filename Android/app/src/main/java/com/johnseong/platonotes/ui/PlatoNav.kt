package com.johnseong.platonotes.ui

import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.johnseong.platonotes.billing.TipJarUi
import com.johnseong.platonotes.billing.TipOption
import com.johnseong.platonotes.data.Note
import com.johnseong.platonotes.data.NoteRepository
import com.johnseong.platonotes.model.Expiry
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.launch

/** Hooks the screens need from the activity: the tip jar's billing client and opening links. */
class AppHooks(
    val tipJar: () -> TipJarUi,
    val startTipJar: () -> Unit,
    val tip: (TipOption) -> Unit,
    val retryTipJar: () -> Unit,
    val dismissTip: () -> Unit,
    val openUrl: (String) -> Unit,
    val version: String,
)

private sealed interface Loaded { data object Loading : Loaded; data class Ready(val note: Note?) : Loaded }

/** Navigation with predictive back (navigation-compose animates the system back gesture). */
@Composable
fun PlatoNav(repo: NoteRepository, appearance: AppearanceStore, hooks: AppHooks) {
    val nav = rememberNavController()
    val scope = rememberCoroutineScope()
    val notes by repo.notes.collectAsStateWithLifecycle(initialValue = emptyList())
    val now by rememberNow()

    // Expired notes go the second they run out while the app is open.
    LaunchedEffect(now, notes) {
        if (notes.any { Expiry.isExpired(it, now) }) repo.purgeExpired()
    }

    NavHost(nav, startDestination = "notes") {
        composable("notes") {
            NotesScreen(
                notes = notes, now = now,
                onOpen = { nav.navigate("note/${it.id}") },
                onCompose = { nav.navigate("compose") },
                onSettings = { nav.navigate("settings") },
                onBurn = { scope.launch { repo.burn(it.id) } },
            )
        }
        composable("note/{id}", arguments = listOf(navArgument("id") { type = NavType.StringType })) { entry ->
            val id = entry.arguments?.getString("id").orEmpty()
            val flow = remember(id) { repo.note(id).map<Note?, Loaded> { Loaded.Ready(it) } }
            val state by flow.collectAsStateWithLifecycle(initialValue = Loaded.Loading)
            val s = state
            if (s is Loaded.Ready) {
                val note = s.note
                if (note == null || Expiry.isExpired(note, now)) {
                    // Burned or expired: leave the note.
                    LaunchedEffect(Unit) { if (nav.currentBackStackEntry?.id == entry.id) nav.popBackStack() }
                } else {
                    DetailScreen(
                        note = note, now = now,
                        onBack = { nav.popBackStack() },
                        onEdit = { t, c -> scope.launch { repo.edit(note, t, c) } },
                        onBurn = { scope.launch { repo.burn(note.id) } },
                    )
                }
            }
        }
        composable("compose") {
            ComposeScreen(
                now = now,
                onClose = { nav.popBackStack() },
                onSave = { t, c, d -> scope.launch { repo.create(t, c, d) }; nav.popBackStack() },
            )
        }
        composable("settings") {
            var sheet by remember { mutableStateOf(false) }
            SettingsScreen(
                appearance = appearance.value, onAppearance = appearance::set, version = hooks.version,
                onBack = { nav.popBackStack() }, onOpenUrl = hooks.openUrl,
                onSupport = { hooks.startTipJar(); sheet = true },
            )
            if (sheet) TipJarSheet(
                ui = hooks.tipJar(), onTip = hooks.tip, onRetry = hooks.retryTipJar,
                onDone = { hooks.dismissTip(); sheet = false },
                onDismiss = { hooks.dismissTip(); sheet = false },
            )
        }
    }
}
