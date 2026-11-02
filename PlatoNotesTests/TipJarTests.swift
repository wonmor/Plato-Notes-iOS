import StoreKit
import StoreKitTest
import XCTest
@testable import PlatoNotes

/// Tip jar against the local StoreKit configuration (StoreKit/TipJar.storekit).
@MainActor
final class TipJarTests: XCTestCase {
    private var session: SKTestSession!

    override func setUp() async throws {
        session = try SKTestSession(configurationFileNamed: "TipJar")
        session.resetToDefaultState()
        session.clearTransactions()
        session.disableDialogs = true
        session.askToBuyEnabled = false
        session.failTransactionsEnabled = false
    }

    override func tearDown() async throws {
        session.clearTransactions()
        session = nil
    }

    func testCopyNeverSaysDonationOrUsesDots() {
        let texts = [TipJar.disclaimer, TipJar.pitch, TipJar.thanks, TipJar.pending, TipJar.unavailable,
                     TipJar.unverified, TipJar.failed("x")] + Array(TipJar.fallbackNames.values)
        for text in texts {
            XCTAssertFalse(text.lowercased().contains("donat"), text)
            XCTAssertFalse(text.lowercased().contains("charit"), text)
            XCTAssertFalse(text.contains("·") || text.contains("•"), text)
        }
        XCTAssertEqual(TipJar.disclaimer, "Tips are optional, unlock nothing, and are not tax-deductible. Plato stays free.")
    }

    func testSortingByPrice() {
        let o = { (id: String, p: String) in TipOption(id: id, name: id, displayPrice: p, price: Decimal(string: p)!) }
        let sorted = TipJar.sorted([o("plato.tip.50", "49.99"), o("plato.tip.1", "0.99"),
                                    o("plato.tip.20", "19.99"), o("plato.tip.5", "4.99")])
        XCTAssertEqual(sorted.map(\.id), TipJar.productIDs)
    }

    func testProductsLoadAsConsumablesInPriceOrder() async throws {
        let store = TipJarStore()
        await store.loadProducts()
        XCTAssertEqual(store.load, .ready)
        XCTAssertEqual(store.options.map(\.id), TipJar.productIDs)
        XCTAssertEqual(store.options.map(\.name), ["Small tip", "Kind tip", "Generous tip", "Big tip"])
        XCTAssertEqual(store.options.map(\.price), [0.99, 4.99, 19.99, 49.99].map { Decimal(string: $0.description)! })
        let products = try await Product.products(for: TipJar.productIDs)
        XCTAssertEqual(products.count, 4)
        XCTAssertTrue(products.allSatisfy { $0.type == .consumable })
    }

    func testSuccessfulTipThanksAndFinishes() async throws {
        let store = TipJarStore()
        await store.loadProducts()
        await store.tip(store.options[1])
        XCTAssertEqual(store.status, .thanked)
        var unfinished = 0
        for await _ in Transaction.unfinished { unfinished += 1 }
        XCTAssertEqual(unfinished, 0, "consumable tips must be finished")
        store.dismissMessage()
        XCTAssertEqual(store.status, .idle)
    }

    func testTipsCanBeRepeated() async throws {
        let store = TipJarStore()
        await store.loadProducts()
        await store.tip(store.options[0])
        XCTAssertEqual(store.status, .thanked)
        store.dismissMessage()
        await store.tip(store.options[0])
        XCTAssertEqual(store.status, .thanked, "a consumable can be bought again")
    }

    func testFailedTipShowsMessage() async throws {
        session.failTransactionsEnabled = true
        session.failureError = .unknown
        let store = TipJarStore()
        await store.loadProducts()
        await store.tip(store.options[0])
        guard case .failed(let text) = store.status else { return XCTFail("expected failure, got \(store.status)") }
        XCTAssertTrue(text.contains("Nothing was charged"))
    }

    func testUnknownProductFailsWithoutCharging() async {
        let store = TipJarStore()
        await store.tip(TipOption(id: "plato.tip.999", name: "x", displayPrice: "$1", price: 1))
        XCTAssertEqual(store.status, .failed(TipJar.unavailable))
    }
}
