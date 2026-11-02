package com.johnseong.platonotes.ui

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
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
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.HourglassBottom
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.foundation.layout.Row
import com.johnseong.platonotes.model.Expiry
import com.johnseong.platonotes.model.ExpiryDuration

/** New note: a full-screen dialog with a title, the text, and how long it lives (5m to 7d, 24h by default). */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ComposeScreen(
    now: Long,
    onClose: () -> Unit,
    onSave: (title: String, content: String, duration: ExpiryDuration) -> Unit,
    initialTitle: String = "",
    initialContent: String = "",
) {
    var title by rememberSaveable { mutableStateOf(initialTitle) }
    var content by rememberSaveable { mutableStateOf(initialContent) }
    var duration by rememberSaveable { mutableStateOf(ExpiryDuration.Default) }
    val canSave = title.isNotBlank() || content.isNotBlank()
    val ink = MaterialTheme.colorScheme.onSurface

    Scaffold(
        containerColor = MaterialTheme.colorScheme.background,
        topBar = {
            TopAppBar(
                title = { Text("New note") },
                navigationIcon = { IconButton(onClick = onClose) { Icon(Icons.Outlined.Close, "Cancel") } },
                actions = {
                    TextButton(onClick = { onSave(title, content, duration) }, enabled = canSave) { Text("Save") }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = MaterialTheme.colorScheme.background),
            )
        },
    ) { padding ->
        Box(Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.TopCenter) {
            Column(Modifier.widthIn(max = 720.dp).fillMaxWidth().verticalScroll(rememberScrollState()).imePadding().padding(bottom = 32.dp)) {
                Group(items = listOf({
                    InlineField(title, { title = it }, "Title",
                        MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.SemiBold, color = ink), singleLine = true)
                }, {
                    InlineField(content, { content = it }, "Write it down. It won't stay.",
                        MaterialTheme.typography.bodyLarge.copy(color = ink), Modifier.heightIn(min = 180.dp))
                }))
                SectionHeader("Vanishes after")
                SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth().padding(horizontal = 16.dp)) {
                    ExpiryDuration.entries.forEachIndexed { i, d ->
                        SegmentedButton(
                            selected = d == duration, onClick = { duration = d },
                            shape = SegmentedButtonDefaults.itemShape(i, ExpiryDuration.entries.size),
                            modifier = Modifier.semantics { contentDescription = d.displayName },
                            icon = {},
                        ) { Text(d.shortName) }
                    }
                }
                Row(Modifier.padding(horizontal = 28.dp, vertical = 10.dp), verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Outlined.HourglassBottom, null, Modifier.size(16.dp), tint = MaterialTheme.colorScheme.onSurfaceVariant)
                    Spacer(Modifier.width(6.dp))
                    val at = Expiry.expiresAt(now, duration)
                    Text("Gone ${vanishTime(at, duration.seconds >= 86_400)}. It can't be recovered.",
                        style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
        }
    }
}
