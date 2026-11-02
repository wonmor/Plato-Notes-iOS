package com.johnseong.platonotes.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.EditNote
import androidx.compose.material.icons.outlined.HourglassBottom
import androidx.compose.material.icons.outlined.LocalFireDepartment
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.BottomAppBar
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.FloatingActionButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LargeTopAppBar
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SwipeToDismissBox
import androidx.compose.material3.SwipeToDismissBoxValue
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.rememberSwipeToDismissBoxState
import androidx.compose.material3.rememberTopAppBarState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.CustomAccessibilityAction
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.customActions
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.johnseong.platonotes.data.Note
import com.johnseong.platonotes.model.Expiry
import com.johnseong.platonotes.model.LifeLevel
import java.text.DateFormat
import java.util.Date

/**
 * The list: "Vanishing soon" (under an hour left, soonest first) and "Later", in grouped cards. Swipe a note
 * left to burn it (after confirming). A bottom bar carries the note count and the new-note button.
 * Stateless, so tests and store screenshots render it with fixed notes and a fixed clock.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NotesScreen(
    notes: List<Note>,
    now: Long,
    onOpen: (Note) -> Unit,
    onCompose: () -> Unit,
    onSettings: () -> Unit,
    onBurn: (Note) -> Unit,
) {
    val (soon, later) = remember(notes, now) { Expiry.sections(notes, now) }
    val count = soon.size + later.size
    var toBurn by remember { mutableStateOf<Note?>(null) }
    val scroll = TopAppBarDefaults.exitUntilCollapsedScrollBehavior(rememberTopAppBarState())

    Scaffold(
        modifier = Modifier.nestedScroll(scroll.nestedScrollConnection),
        containerColor = MaterialTheme.colorScheme.background,
        topBar = {
            LargeTopAppBar(
                title = { Text("Plato") },
                actions = {
                    IconButton(onClick = onSettings) { Icon(Icons.Outlined.Settings, contentDescription = "Settings") }
                },
                scrollBehavior = scroll,
                colors = TopAppBarDefaults.largeTopAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background,
                    scrolledContainerColor = MaterialTheme.colorScheme.surfaceContainerHigh,
                ),
            )
        },
        bottomBar = {
            BottomAppBar(
                containerColor = MaterialTheme.colorScheme.surfaceContainerHigh,
                actions = {
                    Text(
                        Expiry.countLabel(count), Modifier.padding(start = 12.dp).testTag("count"),
                        style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                },
                floatingActionButton = {
                    FloatingActionButton(
                        onClick = onCompose,
                        containerColor = MaterialTheme.colorScheme.primary,
                        contentColor = MaterialTheme.colorScheme.onPrimary,
                        elevation = FloatingActionButtonDefaults.bottomAppBarFabElevation(),
                    ) { Icon(Icons.Outlined.EditNote, contentDescription = "New note") }
                },
            )
        },
    ) { padding ->
        if (count == 0) {
            EmptyState(Modifier.padding(padding), onCompose)
        } else {
            LazyColumn(
                Modifier.fillMaxSize().testTag("notes"),
                contentPadding = PaddingValues(top = padding.calculateTopPadding(), bottom = padding.calculateBottomPadding() + 24.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                if (soon.isNotEmpty()) section("Vanishing soon", Icons.Outlined.HourglassBottom, soon, now, onOpen) { toBurn = it }
                if (later.isNotEmpty()) section("Later", null, later, now, onOpen) { toBurn = it }
            }
        }
    }

    toBurn?.let { note ->
        BurnDialog(onBurn = { onBurn(note); toBurn = null }, onKeep = { toBurn = null })
    }
}

private fun LazyListScope.section(
    title: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector?,
    notes: List<Note>,
    now: Long,
    onOpen: (Note) -> Unit,
    askBurn: (Note) -> Unit,
) {
    item(key = "h-$title") {
        Box(Modifier.widthIn(max = 720.dp)) { SectionHeader(title, icon) }
    }
    itemsIndexed(notes, key = { _, n -> n.id }) { i, note ->
        Box(Modifier.widthIn(max = 720.dp).padding(horizontal = 16.dp).padding(bottom = 2.dp).animateItem()) {
            SwipeToBurn(note, i, notes.size, now, onOpen, askBurn)
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun SwipeToBurn(note: Note, index: Int, count: Int, now: Long, onOpen: (Note) -> Unit, askBurn: (Note) -> Unit) {
    val shape = groupShape(index, count)
    val state = rememberSwipeToDismissBoxState(
        confirmValueChange = { v ->
            // Never dismiss straight away: ask first, and let the row spring back meanwhile.
            if (v == SwipeToDismissBoxValue.EndToStart) askBurn(note)
            false
        },
        positionalThreshold = { it * 0.35f },
    )
    SwipeToDismissBox(
        state = state,
        modifier = Modifier.clip(shape).testTag("row-${note.id}"),
        enableDismissFromStartToEnd = false,
        backgroundContent = {
            Row(
                Modifier.fillMaxSize().background(MaterialTheme.colorScheme.error).padding(horizontal = 24.dp),
                horizontalArrangement = Arrangement.End, verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(Icons.Outlined.LocalFireDepartment, null, tint = MaterialTheme.colorScheme.onError)
                Text("  Burn", color = MaterialTheme.colorScheme.onError, style = MaterialTheme.typography.labelLarge)
            }
        },
    ) {
        NoteRow(note, now, Modifier.clickable { onOpen(note) }.semantics {
            customActions = listOf(CustomAccessibilityAction("Burn") { askBurn(note); true })
        })
    }
}

/** A note row: title and preview that fade as time runs out, and the draining ring with the countdown. */
@Composable
fun NoteRow(note: Note, now: Long, modifier: Modifier = Modifier) {
    val progress = Expiry.progress(note, now)
    val remaining = Expiry.remainingMs(note, now)
    val ink = MaterialTheme.colorScheme.onSurface
    val critical = Expiry.level(progress) == LifeLevel.Critical
    val title = note.title.ifBlank { "Untitled" }
    Row(
        modifier.fillMaxWidth().background(MaterialTheme.colorScheme.surfaceContainerLowest)
            .padding(start = 20.dp, end = 14.dp, top = 14.dp, bottom = 14.dp)
            .semantics(mergeDescendants = true) {
                contentDescription = if (note.title.isBlank()) "Untitled note" else note.title
                stateDescription = Expiry.remainingSpoken(remaining)
            },
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
            Text(title, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold,
                color = ink.copy(alpha = Expiry.inkFade(progress)), maxLines = 1, overflow = TextOverflow.Ellipsis)
            if (note.content.isNotBlank()) {
                Text(note.content, style = MaterialTheme.typography.bodyMedium,
                    color = ink.copy(alpha = Expiry.previewFade(progress)), maxLines = 2, overflow = TextOverflow.Ellipsis)
            }
            Text("Vanishes ${vanishTime(note.expiresAt, remaining > 86_400_000L)}",
                style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
        Column(Modifier.padding(start = 12.dp).widthIn(min = 56.dp), horizontalAlignment = Alignment.CenterHorizontally) {
            LifeRing(progress, Modifier.size(26.dp))
            Spacer(Modifier.height(5.dp))
            Text(Expiry.clock(remaining), style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.SemiBold,
                color = if (critical) LocalLifeColors.current.critical else MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}

fun vanishTime(at: Long, withDate: Boolean): String {
    val d = Date(at)
    return if (withDate) DateFormat.getDateTimeInstance(DateFormat.MEDIUM, DateFormat.SHORT).format(d)
    else DateFormat.getTimeInstance(DateFormat.SHORT).format(d)
}

@Composable
private fun EmptyState(modifier: Modifier, onCompose: () -> Unit) {
    Column(
        modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(horizontal = 32.dp, vertical = 24.dp),
        horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Center,
    ) {
        BrandMark(72.dp)
        Spacer(Modifier.height(16.dp))
        Text("Every note has vanished", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.SemiBold,
            textAlign = TextAlign.Center)
        Spacer(Modifier.height(10.dp))
        Text("Write something down, choose how long it lives, and let it go.", style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant, textAlign = TextAlign.Center)
        Spacer(Modifier.height(18.dp))
        Text("“${Quotes.today()}”\n– Plato", style = MaterialTheme.typography.bodyMedium, fontStyle = FontStyle.Italic,
            color = MaterialTheme.colorScheme.onSurfaceVariant, textAlign = TextAlign.Center, modifier = Modifier.widthIn(max = 420.dp))
        Spacer(Modifier.height(24.dp))
        Button(onClick = onCompose) {
            Icon(Icons.Outlined.EditNote, null, Modifier.size(20.dp))
            Text("  New note")
        }
    }
}

@Composable
fun BurnDialog(onBurn: () -> Unit, onKeep: () -> Unit) {
    AlertDialog(
        onDismissRequest = onKeep,
        icon = { Icon(Icons.Outlined.LocalFireDepartment, null, tint = MaterialTheme.colorScheme.error) },
        title = { Text("Burn this note?") },
        text = { Text("It will be destroyed immediately and can't be recovered.") },
        confirmButton = { TextButton(onClick = onBurn) { Text("Burn", color = MaterialTheme.colorScheme.error) } },
        dismissButton = { TextButton(onClick = onKeep) { Text("Keep") } },
    )
}

object Quotes {
    private val all = listOf(
        "The beginning of wisdom is the definition of terms.",
        "Be kind, for everyone you meet is fighting a hard battle.",
        "Wise men speak because they have something to say.",
        "We can easily forgive a child who is afraid of the dark; the real tragedy is men who are afraid of the light.",
        "The measure of a man is what he does with power.",
        "Thinking: the talking of the soul with itself.",
        "Human behavior flows from three main sources: desire, emotion, and knowledge.",
        "Excellence is not a gift, but a skill that takes practice.",
        "Opinion is the medium between knowledge and ignorance.",
        "There is no harm in repeating a good thing.",
    )

    fun today(): String = all[java.util.Calendar.getInstance().get(java.util.Calendar.DAY_OF_YEAR) % all.size]
}
