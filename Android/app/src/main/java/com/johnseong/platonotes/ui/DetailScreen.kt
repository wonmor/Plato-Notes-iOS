package com.johnseong.platonotes.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.outlined.LocalFireDepartment
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.johnseong.platonotes.data.Note
import com.johnseong.platonotes.model.Expiry
import com.johnseong.platonotes.model.LifeLevel
import java.text.DateFormat
import java.util.Date

/** A note: the countdown ring, the text (editable, fading with time), its timeline, and Burn now. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DetailScreen(
    note: Note,
    now: Long,
    onBack: () -> Unit,
    onEdit: (title: String, content: String) -> Unit,
    onBurn: () -> Unit,
) {
    var title by rememberSaveable(note.id) { mutableStateOf(note.title) }
    var content by rememberSaveable(note.id) { mutableStateOf(note.content) }
    var confirm by remember { mutableStateOf(false) }
    val progress = Expiry.progress(note, now)
    val remaining = Expiry.remainingMs(note, now)
    val fade = Expiry.inkFade(progress)
    val ink = MaterialTheme.colorScheme.onSurface.copy(alpha = fade)
    val critical = Expiry.level(progress) == LifeLevel.Critical

    Scaffold(
        containerColor = MaterialTheme.colorScheme.background,
        topBar = {
            TopAppBar(
                title = { Text(title.ifBlank { "Note" }, maxLines = 1, overflow = TextOverflow.Ellipsis) },
                navigationIcon = { IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Outlined.ArrowBack, "Back") } },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = MaterialTheme.colorScheme.background),
            )
        },
    ) { padding ->
        Box(Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.TopCenter) {
            Column(Modifier.widthIn(max = 720.dp).fillMaxWidth().verticalScroll(rememberScrollState()).imePadding().padding(bottom = 32.dp)) {
                Group(items = listOf({
                    Row(Modifier.padding(horizontal = 20.dp, vertical = 18.dp), verticalAlignment = Alignment.CenterVertically) {
                        LifeRing(progress, Modifier.size(54.dp), strokeWidth = 6.dp)
                        Spacer(Modifier.width(16.dp))
                        Column {
                            Text(Expiry.clock(remaining), style = MaterialTheme.typography.displaySmall, fontWeight = FontWeight.SemiBold,
                                color = if (critical) LocalLifeColors.current.critical else MaterialTheme.colorScheme.onSurface,
                                modifier = Modifier.semantics { contentDescription = Expiry.remainingSpoken(remaining) })
                            Text("left of ${note.duration.displayName}", style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                    }
                }))
                Group(items = listOf({
                    InlineField(title, { title = it; onEdit(it, content) }, "Title",
                        MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.SemiBold, color = ink), singleLine = true)
                }, {
                    InlineField(content, { content = it; onEdit(title, it) }, "Note",
                        MaterialTheme.typography.bodyLarge.copy(color = ink), Modifier.heightIn(min = 220.dp))
                }))
                Group(header = "Timeline", items = listOf({
                    LabeledRow("Written", fullDate(note.createdAt), MaterialTheme.colorScheme.onSurfaceVariant)
                }, {
                    LabeledRow("Vanishes", fullDate(note.expiresAt), MaterialTheme.colorScheme.primary)
                }))
                Group(items = listOf({
                    Row(
                        Modifier.fillMaxWidth().clickable { confirm = true }.padding(horizontal = 20.dp, vertical = 16.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Icon(Icons.Outlined.LocalFireDepartment, null, tint = MaterialTheme.colorScheme.error)
                        Spacer(Modifier.width(14.dp))
                        Text("Burn now", color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodyLarge)
                    }
                }))
            }
        }
    }
    if (confirm) BurnDialog(onBurn = { confirm = false; onBurn() }, onKeep = { confirm = false })
}

@Composable
fun InlineField(
    value: String,
    onChange: (String) -> Unit,
    placeholder: String,
    style: TextStyle,
    modifier: Modifier = Modifier,
    singleLine: Boolean = false,
) {
    TextField(
        value, onChange, modifier.fillMaxWidth(), textStyle = style, singleLine = singleLine,
        placeholder = { Text(placeholder, style = style.copy(color = MaterialTheme.colorScheme.onSurfaceVariant)) },
        keyboardOptions = KeyboardOptions(capitalization = KeyboardCapitalization.Sentences),
        colors = TextFieldDefaults.colors(
            focusedContainerColor = Color.Transparent, unfocusedContainerColor = Color.Transparent,
            focusedIndicatorColor = Color.Transparent, unfocusedIndicatorColor = Color.Transparent,
        ),
    )
}

@Composable
fun LabeledRow(label: String, value: String, valueColor: Color) {
    Row(Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 16.dp), horizontalArrangement = Arrangement.SpaceBetween) {
        Text(label, style = MaterialTheme.typography.bodyLarge)
        Text(value, style = MaterialTheme.typography.bodyLarge, color = valueColor)
    }
}

fun fullDate(at: Long): String = DateFormat.getDateTimeInstance(DateFormat.MEDIUM, DateFormat.SHORT).format(Date(at))
