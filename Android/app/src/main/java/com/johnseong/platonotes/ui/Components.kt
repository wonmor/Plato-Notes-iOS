package com.johnseong.platonotes.ui

import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.State
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalInspectionMode
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.lifecycle.repeatOnLifecycle
import com.johnseong.platonotes.R
import com.johnseong.platonotes.model.Expiry
import kotlinx.coroutines.delay

/** The draining ring: a track and an arc for the life left, coloured accent, then orange, then red. */
@Composable
fun LifeRing(progress: Double, modifier: Modifier = Modifier, strokeWidth: Dp = 3.5.dp) {
    val colors = LocalLifeColors.current
    val p = progress.coerceIn(0.0, 1.0).toFloat()
    val animated by animateFloatAsState(p, tween(if (LocalInspectionMode.current) 0 else 1000, easing = LinearEasing), label = "life")
    val arc = colors.of(Expiry.level(progress))
    Canvas(modifier.clearAndSetSemantics { }) {
        val w = strokeWidth.toPx()
        val inset = w / 2
        val sz = androidx.compose.ui.geometry.Size(size.width - w, size.height - w)
        val tl = androidx.compose.ui.geometry.Offset(inset, inset)
        drawArc(colors.track, 0f, 360f, false, tl, sz, style = Stroke(w))
        if (animated > 0f) drawArc(arc, -90f, 360f * animated, false, tl, sz, style = Stroke(w, cap = StrokeCap.Round))
    }
}

/** The app icon, used as Plato's brand mark. */
@Composable
fun BrandMark(size: Dp = 64.dp) {
    val shape = RoundedCornerShape(size * 0.2237f)
    Image(
        painterResource(R.drawable.brand_mark), contentDescription = null,
        modifier = Modifier.size(size).clip(shape).border(0.5.dp, MaterialTheme.colorScheme.outlineVariant, shape),
    )
}

/** Ticks once a second while the screen is started, so every countdown updates together. */
@Composable
fun rememberNow(clock: () -> Long = System::currentTimeMillis): State<Long> {
    val now = remember { mutableLongStateOf(clock()) }
    val owner = LocalLifecycleOwner.current
    LaunchedEffect(owner) {
        owner.repeatOnLifecycle(Lifecycle.State.STARTED) {
            while (true) {
                now.longValue = clock()
                delay(1000 - now.longValue % 1000)
            }
        }
    }
    return now
}

// ---------- grouped cards (Android 16 style: one rounded group, items split by thin gaps) ----------

private val Outer = 24.dp
private val Inner = 6.dp

/** Shape for item [index] of [count] in a grouped section. */
fun groupShape(index: Int, count: Int) = RoundedCornerShape(
    topStart = if (index == 0) Outer else Inner, topEnd = if (index == 0) Outer else Inner,
    bottomStart = if (index == count - 1) Outer else Inner, bottomEnd = if (index == count - 1) Outer else Inner,
)

@Composable
fun SectionHeader(text: String, icon: ImageVector? = null, modifier: Modifier = Modifier) {
    Row(
        modifier.fillMaxWidth().padding(start = 20.dp, end = 20.dp, top = 20.dp, bottom = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (icon != null) {
            Icon(icon, null, Modifier.size(18.dp), tint = MaterialTheme.colorScheme.primary)
            Spacer(Modifier.width(6.dp))
        }
        Text(text, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.SemiBold,
            color = if (icon != null) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant)
    }
}

/** A grouped section of cards for non-lazy screens (detail, composer, settings). */
@Composable
fun Group(
    modifier: Modifier = Modifier,
    header: String? = null,
    headerIcon: ImageVector? = null,
    footer: (@Composable () -> Unit)? = null,
    items: List<@Composable () -> Unit>,
) {
    Column(modifier.fillMaxWidth()) {
        if (header != null) SectionHeader(header, headerIcon) else Spacer(Modifier.padding(top = 12.dp))
        Column(Modifier.padding(horizontal = 16.dp), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            items.forEachIndexed { i, item ->
                Column(
                    Modifier.fillMaxWidth().clip(groupShape(i, items.size))
                        .background(MaterialTheme.colorScheme.surfaceContainerLowest)
                ) { item() }
            }
        }
        if (footer != null) Row(Modifier.padding(horizontal = 28.dp, vertical = 8.dp)) { footer() }
    }
}
