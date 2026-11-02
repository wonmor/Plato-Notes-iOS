import Foundation
import Observation
import StoreKit

/// The tip jar: four consumable in-app purchases that unlock nothing. They are tips to the developer
/// (Orchestr Aerospace Inc. is not a charity), so the app never calls them donations.
enum TipJar {
    static let productIDs = ["plato.tip.1", "plato.tip.5", "plato.tip.20", "plato.tip.50"]

    static let disclaimer = "Tips are optional, unlock nothing, and are not tax-deductible. Plato stays free."

    static let pitch = "Plato is free, with no ads, no account and no tracking. If it has been useful, you can leave a tip to support its development."

    /// Names used when the store has not supplied one (the store's localized name wins).
    static let fallbackNames = [
        "plato.tip.1": "Small tip",
        "plato.tip.5": "Kind tip",
        "plato.tip.20": "Generous tip",
        "plato.tip.50": "Big tip",
    ]

    static let thanks = "Your tip helps keep Plato free, private and on your device. It means a great deal."
    static let pending = "Your tip is waiting for approval, for example through Ask to Buy. There's nothing more to do here. If it goes through, thank you."
    static let unavailable = "The tip jar can't reach the App Store right now. Check your connection and try again."
    static let unverified = "The App Store couldn't verify that purchase, so it wasn't completed."

    static func failed(_ reason: String) -> String {
        "The tip didn't go through (\(reason)). Nothing was charged."
    }

    /// Store order: by price, then by the fixed id order.
    static func sorted(_ options: [TipOption]) -> [TipOption] {
        options.sorted {
            $0.price != $1.price ? $0.price < $1.price
                : (productIDs.firstIndex(of: $0.id) ?? 0) < (productIDs.firstIndex(of: $1.id) ?? 0)
        }
    }
}

struct TipOption: Identifiable, Equatable {
    let id: String
    let name: String
    let displayPrice: String
    let price: Decimal
}

enum TipStatus: Equatable {
    case idle
    case purchasing(String)
    case pending
    case thanked
    case failed(String)
}

@MainActor
@Observable
final class TipJarStore {
    enum Load: Equatable { case idle, loading, ready, unavailable }

    private(set) var options: [TipOption] = []
    private(set) var load: Load = .idle
    var status: TipStatus = .idle

    var isPurchasing: Bool {
        if case .purchasing = status { return true }
        return false
    }

    @ObservationIgnored private var products: [String: Product] = [:]
    @ObservationIgnored private var updates: Task<Void, Never>?
    @ObservationIgnored private var started = false

    init() {}

    /// Called at launch: listens for transactions (Ask to Buy approvals, interrupted purchases)
    /// and finishes any tip left unfinished by a previous launch. Prices load when the sheet opens.
    func start() {
        guard !started else { return }
        started = true
        #if DEBUG
        if Self.previewing { return }
        #endif
        updates = Task { [weak self] in
            for await result in Transaction.updates { await self?.handle(update: result) }
        }
        Task {
            for await result in Transaction.unfinished {
                if case .verified(let t) = result, TipJar.productIDs.contains(t.productID) { await t.finish() }
            }
        }
    }

    /// Loads prices once; call again after a failure to retry.
    func loadIfNeeded() async {
        guard load == .idle || load == .unavailable else { return }
        await loadProducts()
    }

    func loadProducts() async {
        #if DEBUG
        if Self.previewing { stagePreview(); return }
        #endif
        load = .loading
        do {
            let found = try await Product.products(for: TipJar.productIDs)
            products = Dictionary(uniqueKeysWithValues: found.map { ($0.id, $0) })
            options = TipJar.sorted(found.map {
                TipOption(id: $0.id,
                          name: $0.displayName.isEmpty ? (TipJar.fallbackNames[$0.id] ?? $0.id) : $0.displayName,
                          displayPrice: $0.displayPrice, price: $0.price)
            })
            load = options.isEmpty ? .unavailable : .ready
        } catch {
            load = .unavailable
        }
    }

    func tip(_ option: TipOption) async {
        guard let product = products[option.id] else {
            #if DEBUG
            if Self.previewing { status = .thanked; return }
            #endif
            status = .failed(TipJar.unavailable)
            return
        }
        status = .purchasing(option.id)
        do {
            switch try await product.purchase() {
            case .success(.verified(let transaction)):
                await transaction.finish()
                status = .thanked
            case .success(.unverified):
                status = .failed(TipJar.unverified)
            case .pending:
                status = .pending
            case .userCancelled:
                status = .idle
            @unknown default:
                status = .idle
            }
        } catch {
            status = .failed(TipJar.failed(Self.reason(error)))
        }
    }

    func dismissMessage() { status = .idle }

    private func handle(update result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result else { return }
        await transaction.finish()
        // A tip that was pending (Ask to Buy) and has now gone through.
        if TipJar.productIDs.contains(transaction.productID), transaction.revocationDate == nil, status == .pending {
            status = .thanked
        }
    }

    static func reason(_ error: Error) -> String {
        if let e = error as? StoreKitError {
            switch e {
            case .networkError: return "no connection to the App Store"
            case .notAvailableInStorefront: return "not available in your country or region"
            case .notEntitled: return "this Apple Account can't make purchases"
            default: break
            }
        }
        if let e = error as? Product.PurchaseError, e == .purchaseNotAllowed { return "purchases aren't allowed on this device" }
        return "the App Store returned an error"
    }

    #if DEBUG
    /// Screenshot staging (`-PlatoTipPreview`, optionally `-PlatoTipThanks`): the US prices set on App Store Connect.
    static var previewing: Bool { ProcessInfo.processInfo.arguments.contains("-PlatoTipPreview") }

    private func stagePreview() {
        options = zip(TipJar.productIDs, ["0.99", "4.99", "19.99", "49.99"]).map { id, p in
            TipOption(id: id, name: TipJar.fallbackNames[id]!, displayPrice: "$" + p, price: Decimal(string: p)!)
        }
        load = .ready
        if ProcessInfo.processInfo.arguments.contains("-PlatoTipThanks") { status = .thanked }
    }
    #endif
}
