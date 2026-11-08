package com.johnseong.platonotes.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.automirrored.outlined.OpenInNew
import androidx.compose.material.icons.outlined.Code
import androidx.compose.material.icons.outlined.Favorite
import androidx.compose.material.icons.outlined.LocalFireDepartment
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material.icons.outlined.Policy
import androidx.compose.material.icons.outlined.Timer
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LargeTopAppBar
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.material3.rememberTopAppBarState
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.johnseong.platonotes.billing.TipJar
import com.johnseong.platonotes.billing.TipJarUi
import com.johnseong.platonotes.billing.TipLoad
import com.johnseong.platonotes.billing.TipOption
import com.johnseong.platonotes.billing.TipStatus

const val SOURCE_URL = "https://github.com/wonmor/Plato-Notes-iOS"
const val PRIVACY_URL = "https://wonmor.github.io/Plato-Notes-iOS/"

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    appearance: Appearance,
    onAppearance: (Appearance) -> Unit,
    version: String,
    onBack: () -> Unit,
    onOpenUrl: (String) -> Unit,
    onSupport: () -> Unit,
) {
    val scroll = TopAppBarDefaults.exitUntilCollapsedScrollBehavior(rememberTopAppBarState())
    Scaffold(
        modifier = Modifier.nestedScroll(scroll.nestedScrollConnection),
        containerColor = MaterialTheme.colorScheme.background,
        topBar = {
            LargeTopAppBar(
                title = { Text("Settings") },
                navigationIcon = { IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Outlined.ArrowBack, "Back") } },
                scrollBehavior = scroll,
                colors = TopAppBarDefaults.largeTopAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background,
                    scrolledContainerColor = MaterialTheme.colorScheme.surfaceContainerHigh,
                ),
            )
        },
    ) { padding ->
        Box(Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.TopCenter) {
            Column(Modifier.widthIn(max = 720.dp).fillMaxWidth().verticalScroll(rememberScrollState()).padding(bottom = 32.dp)) {
                Group(items = listOf({
                    Row(Modifier.padding(20.dp), verticalAlignment = Alignment.CenterVertically) {
                        BrandMark(60.dp)
                        Spacer(Modifier.width(16.dp))
                        Column {
                            Text("Plato", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.SemiBold)
                            Text("Notes that vanish.", style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                    }
                }))
                SectionHeader("Appearance")
                SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth().padding(horizontal = 16.dp)) {
                    Appearance.entries.forEachIndexed { i, a ->
                        SegmentedButton(
                            selected = a == appearance, onClick = { onAppearance(a) },
                            shape = SegmentedButtonDefaults.itemShape(i, Appearance.entries.size),
                        ) { Text(a.title) }
                    }
                }
                Group(header = "How it works", items = listOf(
                    { InfoRow(Icons.Outlined.Timer, "Every note has a timer, from 5 minutes to 7 days.") },
                    { InfoRow(Icons.Outlined.LocalFireDepartment, "When it runs out, the note is deleted for good. Burn it sooner from the note or with a swipe.") },
                    { InfoRow(Icons.Outlined.Lock, "Notes stay on this device. No account, no sync, no tracking.") },
                ))
                Group(header = "Tip jar", items = listOf({
                    LinkRow(Icons.Outlined.Favorite, "Support Plato", Modifier.testTag("support"), trailing = null, onClick = onSupport)
                }))
                Group(items = listOf(
                    { LabeledRow("Version", version, MaterialTheme.colorScheme.onSurfaceVariant) },
                    { LinkRow(Icons.Outlined.Policy, "Privacy policy") { onOpenUrl(PRIVACY_URL) } },
                    { LinkRow(Icons.Outlined.Code, "Source code") { onOpenUrl(SOURCE_URL) } },
                ))
            }
        }
    }
}

@Composable
private fun InfoRow(icon: ImageVector, text: String) {
    Row(Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 14.dp), verticalAlignment = Alignment.CenterVertically) {
        Icon(icon, null, tint = MaterialTheme.colorScheme.primary)
        Spacer(Modifier.width(16.dp))
        Text(text, style = MaterialTheme.typography.bodyLarge)
    }
}

@Composable
private fun LinkRow(
    icon: ImageVector,
    text: String,
    modifier: Modifier = Modifier,
    trailing: ImageVector? = Icons.AutoMirrored.Outlined.OpenInNew,
    onClick: () -> Unit,
) {
    Row(
        modifier.fillMaxWidth().clickable(onClick = onClick).padding(horizontal = 20.dp, vertical = 16.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(icon, null, tint = MaterialTheme.colorScheme.primary)
        Spacer(Modifier.width(16.dp))
        Text(text, style = MaterialTheme.typography.bodyLarge, modifier = Modifier.weight(1f))
        if (trailing != null) Icon(trailing, null, Modifier.size(18.dp), tint = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}

// ---------- tip jar ----------

/** The "Support Plato" sheet. Opened only from Settings; never shown unprompted. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TipJarSheet(ui: TipJarUi, onTip: (TipOption) -> Unit, onRetry: () -> Unit, onDone: () -> Unit, onDismiss: () -> Unit) {
    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
        containerColor = MaterialTheme.colorScheme.background) {
        TipJarContent(ui, onTip, onRetry, onDone, Modifier.navigationBarsPadding())
    }
}

@Composable
fun TipJarContent(ui: TipJarUi, onTip: (TipOption) -> Unit, onRetry: () -> Unit, onDone: () -> Unit, modifier: Modifier = Modifier) {
    Column(modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(bottom = 24.dp),
        horizontalAlignment = Alignment.CenterHorizontally) {
        Column(Modifier.widthIn(max = 560.dp).padding(horizontal = 24.dp), horizontalAlignment = Alignment.CenterHorizontally) {
            BrandMark(56.dp)
            Spacer(Modifier.height(12.dp))
            Text("Support Plato", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.SemiBold)
            Spacer(Modifier.height(8.dp))
        }
        when (val s = ui.status) {
            TipStatus.Thanked -> Message(Icons.Outlined.Favorite, TipJar.THANKS, "Done", onDone)
            TipStatus.Pending -> Message(null, TipJar.PENDING, "OK", onDone)
            is TipStatus.Failed -> Message(null, s.message, "OK", onDone)
            else -> {
                Text(TipJar.INTRO, Modifier.widthIn(max = 560.dp).padding(horizontal = 24.dp), textAlign = TextAlign.Center,
                    style = MaterialTheme.typography.bodyLarge, color = MaterialTheme.colorScheme.onSurfaceVariant)
                when (ui.load) {
                    TipLoad.Loading -> CircularProgressIndicator(Modifier.padding(32.dp))
                    TipLoad.Unavailable -> Message(null, ui.detail?.let { "${TipJar.UNAVAILABLE}\n$it" } ?: TipJar.UNAVAILABLE, "Try again", onRetry)
                    TipLoad.Ready -> Box(Modifier.widthIn(max = 560.dp)) {
                        Group(items = ui.options.map { o -> {
                            val busy = (s as? TipStatus.Purchasing)?.id == o.id
                            Row(
                                Modifier.fillMaxWidth().clickable(enabled = s !is TipStatus.Purchasing) { onTip(o) }
                                    .padding(horizontal = 20.dp, vertical = 14.dp).testTag("tip-${o.id}"),
                                verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween,
                            ) {
                                Text(o.name, style = MaterialTheme.typography.bodyLarge)
                                if (busy) CircularProgressIndicator(Modifier.size(20.dp), strokeWidth = 2.dp)
                                else Text(o.price, style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.primary,
                                    fontWeight = FontWeight.SemiBold)
                            }
                        } })
                    }
                }
            }
        }
        Text(TipJar.DISCLAIMER, Modifier.widthIn(max = 560.dp).padding(horizontal = 28.dp, vertical = 12.dp),
            style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant, textAlign = TextAlign.Center)
    }
}

@Composable
private fun Message(icon: ImageVector?, text: String, button: String, onClick: () -> Unit) {
    Column(Modifier.widthIn(max = 560.dp).padding(horizontal = 24.dp, vertical = 8.dp), horizontalAlignment = Alignment.CenterHorizontally) {
        if (icon != null) Icon(icon, null, Modifier.size(32.dp).padding(bottom = 4.dp), tint = MaterialTheme.colorScheme.primary)
        Text(text, textAlign = TextAlign.Center, style = MaterialTheme.typography.bodyLarge)
        Spacer(Modifier.height(16.dp))
        if (icon != null) Button(onClick = onClick) { Text(button) } else OutlinedButton(onClick = onClick) { Text(button) }
    }
}
