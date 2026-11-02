package com.johnseong.platonotes.billing

import android.app.Activity
import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.android.billingclient.api.*
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

/**
 * Play Billing for the tip jar. Every purchased tip is consumed (never acknowledged-and-kept), so it can be
 * bought again and grants nothing. Pending purchases are consumed once Play reports them as purchased.
 */
class TipJarBilling(context: Context) : PurchasesUpdatedListener {
    var ui by mutableStateOf(TipJarUi())
        private set

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private val details = mutableMapOf<String, ProductDetails>()
    private val client = BillingClient.newBuilder(context.applicationContext)
        .setListener(this)
        .enablePendingPurchases(PendingPurchasesParams.newBuilder().enableOneTimeProducts().build())
        .enableAutoServiceReconnection()
        .build()

    fun start() {
        if (client.isReady) return
        ui = ui.copy(load = TipLoad.Loading)
        client.startConnection(object : BillingClientStateListener {
            override fun onBillingSetupFinished(result: BillingResult) {
                scope.launch {
                    if (result.responseCode != BillingClient.BillingResponseCode.OK) { ui = ui.copy(load = TipLoad.Unavailable); return@launch }
                    consumeLeftovers()
                    loadProducts()
                }
            }
            override fun onBillingServiceDisconnected() { /* auto reconnection is enabled */ }
        })
    }

    fun retry() { if (client.isReady) scope.launch { loadProducts() } else start() }

    private suspend fun loadProducts() {
        ui = ui.copy(load = TipLoad.Loading)
        val params = QueryProductDetailsParams.newBuilder().setProductList(TipJar.productIds.map {
            QueryProductDetailsParams.Product.newBuilder().setProductId(it).setProductType(BillingClient.ProductType.INAPP).build()
        }).build()
        val r = client.queryProductDetails(params)
        val list = r.productDetailsList.orEmpty()
        details.clear(); list.forEach { details[it.productId] = it }
        val options = list.mapNotNull { d ->
            val offer = d.oneTimePurchaseOfferDetails ?: return@mapNotNull null
            TipOption(d.productId, d.name.ifBlank { TipJar.fallbackNames[d.productId] ?: d.productId },
                offer.formattedPrice, offer.priceAmountMicros)
        }
        ui = ui.copy(load = if (r.billingResult.responseCode == BillingClient.BillingResponseCode.OK && options.isNotEmpty())
            TipLoad.Ready else TipLoad.Unavailable, options = TipJar.sorted(options))
    }

    fun tip(activity: Activity, option: TipOption) {
        val d = details[option.id] ?: run { ui = ui.copy(status = TipStatus.Failed(TipJar.UNAVAILABLE)); return }
        val params = BillingFlowParams.newBuilder().setProductDetailsParamsList(listOf(
            BillingFlowParams.ProductDetailsParams.newBuilder().setProductDetails(d).build())).build()
        ui = ui.copy(status = TipStatus.Purchasing(option.id))
        val result = client.launchBillingFlow(activity, params)
        if (result.responseCode != BillingClient.BillingResponseCode.OK) ui = ui.copy(status = TipJar.outcome(result.responseCode, emptyList()))
    }

    fun dismiss() { ui = ui.copy(status = TipStatus.Idle) }

    override fun onPurchasesUpdated(result: BillingResult, purchases: MutableList<Purchase>?) {
        val list = purchases.orEmpty().filter { p -> p.products.any { it in TipJar.productIds } }
        val status = TipJar.outcome(result.responseCode, list.map { it.purchaseState })
        // A late update for a pending tip (no flow on screen) only upgrades Pending to Thanked.
        if (ui.status is TipStatus.Purchasing || status == TipStatus.Thanked || ui.status == TipStatus.Pending) ui = ui.copy(status = status)
        scope.launch { list.filter { it.purchaseState == Purchase.PurchaseState.PURCHASED }.forEach { consume(it) } }
    }

    /** Tips bought while the app was closed, or still pending at last launch. */
    private suspend fun consumeLeftovers() {
        val r = client.queryPurchasesAsync(QueryPurchasesParams.newBuilder().setProductType(BillingClient.ProductType.INAPP).build())
        r.purchasesList.filter { it.purchaseState == Purchase.PurchaseState.PURCHASED }.forEach { consume(it) }
    }

    private suspend fun consume(p: Purchase) {
        client.consumePurchase(ConsumeParams.newBuilder().setPurchaseToken(p.purchaseToken).build())
    }

    fun close() { scope.cancel(); client.endConnection() }
}
