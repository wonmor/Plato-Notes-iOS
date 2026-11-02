package com.johnseong.platonotes

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.test.swipeLeft
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.johnseong.platonotes.data.Note
import com.johnseong.platonotes.ui.NotesScreen
import com.johnseong.platonotes.ui.PlatoTheme
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.annotation.Config
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.hasAnyDescendant
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.performSemanticsAction
import androidx.compose.ui.semantics.SemanticsActions

@RunWith(AndroidJUnit4::class)
@Config(qualifiers = "w411dp-h914dp-xxhdpi")
class NotesScreenTest {
    @get:Rule val rule = createComposeRule()

    private val burned = mutableListOf<String>()
    private val opened = mutableListOf<String>()
    private var composed = 0

    private fun show(notes: List<Note>, now: Long = Fixtures.NOW) = rule.setContent {
        PlatoTheme(false) {
            NotesScreen(notes, now, onOpen = { opened += it.id }, onCompose = { composed++ }, onSettings = {}, onBurn = { burned += it.id })
        }
    }

    @Test fun sectionsAndCount() {
        show(Fixtures.notes())
        rule.onNodeWithText("Vanishing soon").assertIsDisplayed()
        rule.onNodeWithText("Later").assertIsDisplayed()
        rule.onNodeWithTag("count").assertIsDisplayed()
        rule.onNodeWithText("5 notes").assertIsDisplayed()
        rule.onNodeWithText("2:20").assertIsDisplayed()       // Parking, 140 s left
        rule.onNodeWithText("21:00").assertIsDisplayed()      // Gate code, 1260 s left
    }

    @Test fun expiredNotesAreHidden() {
        show(Fixtures.notes(), now = Fixtures.NOW + 200_000)    // Parking has run out
        rule.onAllNodesWithText("Parking").assertCountEquals(0)
        rule.onNodeWithText("4 notes").assertIsDisplayed()
    }

    @Test fun emptyState() {
        show(emptyList())
        rule.onNodeWithText("Every note has vanished").assertIsDisplayed()
        rule.onNodeWithText("No notes").assertIsDisplayed()
        rule.onNodeWithContentDescription("New note").performClick()
        assertEquals(1, composed)
    }

    @Test fun accessibilityBurnAction() {
        show(Fixtures.notes())
        askBurn("Parking")
        rule.onNodeWithText("Burn this note?").assertIsDisplayed()
        rule.onNodeWithText("Burn").performClick()
        assertEquals(listOf("n4"), burned)
    }

    private fun askBurn(title: String) {
        val actions = rule.onNodeWithText(title).fetchSemanticsNode().config[SemanticsActions.CustomActions]
        rule.runOnIdle { actions.first { it.label == "Burn" }.action() }
    }

    @Test fun keepCancels() {
        show(Fixtures.notes())
        askBurn("Gate code for Friday")
        rule.onNodeWithText("Keep").performClick()
        rule.onAllNodesWithText("Burn this note?").assertCountEquals(0)
        assertEquals(emptyList<String>(), burned)
    }

    @Test fun tapOpens() {
        show(Fixtures.notes())
        rule.onNode(hasClickAction() and hasAnyDescendant(hasText("Draft reply to Sam")), useUnmergedTree = true)
            .performSemanticsAction(SemanticsActions.OnClick)
        assertEquals(listOf("n1"), opened)
    }
}
