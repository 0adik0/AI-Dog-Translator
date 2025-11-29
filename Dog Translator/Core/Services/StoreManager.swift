import Foundation
import StoreKit
import Combine

@MainActor
class StoreManager: ObservableObject {

    private let productIDs = [
        "com.god.dogtranslator.pro.weekly",
        "com.god.dogtranslator.pro.monthly",
        "com.god.dogtranslator.pro.yearly"
    ]

    @Published var products: [Product] = []
    @Published var isPro: Bool = false
    @Published var isLoading: Bool = false
    @Published var error: Error?

    private var transactionListener: Task<Void, Never>? = nil

    init() {
        transactionListener = listenForTransactions()
        Task {
            await checkCurrentEntitlements()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    func loadProducts() async {
        guard !isLoading, products.isEmpty else { return }
        isLoading = true
        print("🟣 StoreManager: загружаю продукты...")

        do {
            let storeProducts = try await Product.products(for: productIDs)

            self.products = storeProducts.sorted {
                let lhs = $0.subscription?.subscriptionPeriod.duration ?? 0
                let rhs = $1.subscription?.subscriptionPeriod.duration ?? 0
                return lhs < rhs
            }

            print("✅ StoreManager: продукты загружены: \(products.map { $0.id })")
        } catch {
            print("❌ StoreManager: ошибка загрузки продуктов: \(error.localizedDescription)")
            self.error = error
        }

        isLoading = false
    }

    func purchase(_ product: Product) async {
        isLoading = true
        print("🟣 StoreManager: начинаю покупку \(product.id)...")

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                await handle(transaction: verification)
            case .pending:
                print("🕓 StoreManager: покупка в ожидании")
                self.error = StoreError.purchasePending
            case .userCancelled:
                print("🛑 StoreManager: пользователь отменил покупку")
                break
            @unknown default:
                self.error = StoreError.unknown
            }
        } catch {
            print("❌ StoreManager: ошибка при покупке: \(error)")
            self.error = error
        }

        isLoading = false
    }

    func restorePurchases() async {
        isLoading = true
        print("🔄 StoreManager: восстанавливаю покупки...")

        do {
            try await AppStore.sync()
            await checkCurrentEntitlements()
        } catch {
            print("❌ StoreManager: ошибка восстановления покупок: \(error.localizedDescription)")
            self.error = error
        }

        isLoading = false
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached(priority: .background) { [weak self] in
            for await result in Transaction.updates {
                await self?.handle(transaction: result)
            }
        }
    }

    private func handle(transaction verificationResult: VerificationResult<Transaction>) async {
        switch verificationResult {
        case .verified(let transaction):
            print("✅ StoreManager: транзакция \(transaction.id) подтверждена")
            if transaction.revocationDate == nil {
                await updateProStatus(for: transaction)
            } else {
                await updateProStatus(for: transaction, isRevoked: true)
            }
            await transaction.finish()

        case .unverified:
            print("⚠️ StoreManager: транзакция не прошла верификацию")
            self.error = StoreError.verificationFailed
        }
    }

    private func checkCurrentEntitlements() async {
        print("🔍 StoreManager: проверяю активные подписки...")
        for await result in Transaction.currentEntitlements {
            await handle(transaction: result)
        }
    }

    private func updateProStatus(for transaction: Transaction, isRevoked: Bool = false) async {
        if productIDs.contains(transaction.productID), !isRevoked {
            print("✨ StoreManager: PRO активен (\(transaction.productID))")
            self.isPro = true
        } else {
            print("💤 StoreManager: PRO не активен")
            self.isPro = false
        }
    }
}

enum StoreError: Error, LocalizedError {
    case purchasePending
    case verificationFailed
    case unknown

    var errorDescription: String? {
        switch self {
        case .purchasePending: return "Purchase is pending approval."
        case .verificationFailed: return "Transaction verification failed."
        case .unknown: return "An unknown error occurred."
        }
    }
}

extension Product.SubscriptionPeriod {

    var duration: Int {
        switch unit {
        case .day: return value
        case .week: return value * 7
        case .month: return value * 30
        case .year: return value * 365
        @unknown default: return value
        }
    }
}
