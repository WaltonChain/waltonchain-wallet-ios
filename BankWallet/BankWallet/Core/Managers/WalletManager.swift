import RxSwift

class WalletManager {
    private let accountManager: IAccountManager
    private let walletFactory: IWalletFactory
    private let storage: IWalletStorage

    private let disposeBag = DisposeBag()
    private let subject = PublishSubject<[Wallet]>()

    private let queue = DispatchQueue(label: "io.waltonchain.wallet_manager", qos: .userInitiated)
    private var cachedWallets = [Wallet]()

    init(accountManager: IAccountManager, walletFactory: IWalletFactory, storage: IWalletStorage) {
        self.accountManager = accountManager
        self.walletFactory = walletFactory
        self.storage = storage
    }

    private func notify() {
        subject.onNext(cachedWallets)
    }

}

extension WalletManager: IWalletManager {

    var wallets: [Wallet] {
        queue.sync { cachedWallets }
    }

    var walletsUpdatedObservable: Observable<[Wallet]> {
        subject.asObservable()
    }

    func wallet(coin: Coin) -> Wallet? {
        guard let account = accountManager.account(coinType: coin.type) else {
            return nil
        }

        return walletFactory.wallet(coin: coin, account: account, coinSettings: [:])
    }

    func preloadWallets() {
        let wallets = storage.wallets(accounts: accountManager.accounts)

        queue.async {
            self.cachedWallets = wallets
            self.notify()
        }
    }

    func save(wallets: [Wallet]) {
        storage.save(wallets: wallets)

        queue.async {
            self.cachedWallets.append(contentsOf: wallets)
            self.notify()
        }
    }

    func delete(wallets: [Wallet]) {
        storage.delete(wallets: wallets)

        queue.async {
            self.cachedWallets.removeAll { wallets.contains($0) }
            self.notify()
        }
    }

    func clearWallets() {
        storage.clearWallets()
    }

}
