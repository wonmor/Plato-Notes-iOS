package com.johnseong.platonotes

import com.android.billingclient.api.BillingClient.BillingResponseCode
import com.android.billingclient.api.Purchase.PurchaseState
import com.johnseong.platonotes.billing.TipJar
import com.johnseong.platonotes.billing.TipJarUi
import com.johnseong.platonotes.billing.TipOption
import com.johnseong.platonotes.billing.TipStatus
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class TipJarTest {
    @Test fun outcomes() {
        assertEquals(TipStatus.Thanked, TipJar.outcome(BillingResponseCode.OK, listOf(PurchaseState.PURCHASED)))
        assertEquals(TipStatus.Pending, TipJar.outcome(BillingResponseCode.OK, listOf(PurchaseState.PENDING)))
        assertEquals(TipStatus.Idle, TipJar.outcome(BillingResponseCode.USER_CANCELED, emptyList()))
        val failed = TipJar.outcome(BillingResponseCode.NETWORK_ERROR, emptyList())
        assertTrue(failed is TipStatus.Failed && failed.message.contains("Nothing was charged"))
    }

    @Test fun sortedByPrice() {
        val o = { id: String, m: Long -> TipOption(id, id, "", m) }
        assertEquals(TipJar.productIds, TipJar.sorted(listOf(o("plato.tip.50", 49_990_000), o("plato.tip.1", 990_000),
            o("plato.tip.20", 19_990_000), o("plato.tip.5", 4_990_000))).map { it.id })
    }

    @Test fun copy() {
        assertEquals(listOf("plato.tip.1", "plato.tip.5", "plato.tip.20", "plato.tip.50"), TipJar.productIds)
        assertEquals("Tips are optional, unlock nothing, and are not tax-deductible. Plato stays free.", TipJar.DISCLAIMER)
        val all = listOf(TipJar.DISCLAIMER, TipJar.INTRO, TipJar.THANKS, TipJar.PENDING, TipJar.UNAVAILABLE, TipJar.failed("x")) +
            TipJar.fallbackNames.values
        all.forEach { assertFalse(it, it.lowercase().contains("donat") || it.contains("·") || it.contains("•")) }
        assertEquals(listOf("$0.99", "$4.99", "$19.99", "$49.99"), TipJarUi.preview().options.map { it.price })
    }
}
