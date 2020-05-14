import Foundation
import RxSwift
import CurrencyKit

class TransactionsInteractor {
    private let disposeBag = DisposeBag()
    private var lastBlockHeightsDisposeBag = DisposeBag()
    private var ratesDisposeBag = DisposeBag()
    private var transactionRecordsDisposeBag = DisposeBag()

    weak var delegate: ITransactionsInteractorDelegate?

    private let walletManager: IWalletManager
    private let adapterManager: IAdapterManager
    private let currencyKit: ICurrencyKit
    private let rateManager: IRateManager
    private let reachabilityManager: IReachabilityManager

    private var requestedTimestamps = [(Coin, Date)]()

    init(walletManager: IWalletManager, adapterManager: IAdapterManager, currencyKit: ICurrencyKit, rateManager: IRateManager, reachabilityManager: IReachabilityManager) {
        self.walletManager = walletManager
        self.adapterManager = adapterManager
        self.currencyKit = currencyKit
        self.rateManager = rateManager
        self.reachabilityManager = reachabilityManager
    }

    private func onUpdateCoinsData() {
        transactionRecordsDisposeBag = DisposeBag()
        var walletsData = [(Wallet, Int, LastBlockInfo?)]()

        for wallet in walletManager.wallets {
            if let adapter = adapterManager.transactionsAdapter(for: wallet) {
                walletsData.append((wallet, adapter.confirmationsThreshold, adapter.lastBlockInfo))

                adapter.transactionRecordsObservable
                        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                        .observeOn(MainScheduler.instance)
                        .subscribe(onNext: { [weak self] records in
                            self?.delegate?.didUpdate(records: records, wallet: wallet)
                        })
                        .disposed(by: transactionRecordsDisposeBag)
            }
        }

        delegate?.onUpdate(walletsData: walletsData)
    }

    private func onReachabilityChange() {
        if reachabilityManager.isReachable {
            delegate?.onConnectionRestore()
        }
    }

}

extension TransactionsInteractor: ITransactionsInteractor {

    func initialFetch() {
        onUpdateCoinsData()

        adapterManager.adaptersReadyObservable
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] in
                    self?.onUpdateCoinsData()
                })
                .disposed(by: disposeBag)

        currencyKit.baseCurrencyUpdatedObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] _ in
                    self?.ratesDisposeBag = DisposeBag()
                    self?.requestedTimestamps = []
                    self?.delegate?.onUpdateBaseCurrency()
                })
                .disposed(by: disposeBag)

        reachabilityManager.reachabilitySignal
                .subscribe(onNext: { [weak self] in
                    self?.onReachabilityChange()
                })
                .disposed(by: disposeBag)
    }

    func fetchLastBlockHeights() {
        lastBlockHeightsDisposeBag = DisposeBag()

        for wallet in walletManager.wallets {
            guard let adapter = adapterManager.transactionsAdapter(for: wallet) else {
                continue
            }

            adapter.lastBlockUpdatedObservable
                    .throttle(.seconds(3), latest: true, scheduler: ConcurrentDispatchQueueScheduler(qos: .background))
                    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] in
                        if let lastBlockInfo = adapter.lastBlockInfo {
                            self?.delegate?.onUpdate(lastBlockInfo: lastBlockInfo, wallet: wallet)
                        }
                    })
                    .disposed(by: lastBlockHeightsDisposeBag)
        }
    }

    func fetchRecords(fetchDataList: [FetchData], initial: Bool) {
        guard !fetchDataList.isEmpty else {
            delegate?.didFetch(recordsData: [:], initial: initial)
            return
        }

        var singles = [Single<(Wallet, [TransactionRecord])>]()

        for fetchData in fetchDataList {
            let wallet = walletManager.wallets.first(where: { $0 == fetchData.wallet })
            let single: Single<(Wallet, [TransactionRecord])>

            if let wallet = wallet, let adapter = adapterManager.transactionsAdapter(for: wallet) {
                single = adapter.transactionsSingle(from: fetchData.from, limit: fetchData.limit)
                        .map { records -> (Wallet, [TransactionRecord]) in
                            (fetchData.wallet, records)
                        }
            } else {
                single = Single.just((fetchData.wallet, []))
            }

            singles.append(single)
        }

        Single.zip(singles)
                { tuples -> [Wallet: [TransactionRecord]] in
                    var recordsData = [Wallet: [TransactionRecord]]()

                    for (coin, records) in tuples {
                        recordsData[coin] = records
                    }

                    return recordsData
                }
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] recordsData in
                    self?.delegate?.didFetch(recordsData: recordsData, initial: initial)
                })
                .disposed(by: disposeBag)
    }

    func set(selectedWallets: [Wallet]) {
        let allWallets = walletManager.wallets
        delegate?.onUpdate(selectedCoins: selectedWallets.isEmpty ? allWallets : selectedWallets)
    }

    func fetchRate(coin: Coin, date: Date) {
        guard !requestedTimestamps.contains(where: { $0 == coin && $1 == date }) else {
            return
        }

        requestedTimestamps.append((coin, date))

        let currency = currencyKit.baseCurrency

        rateManager.historicalRate(coinCode: coin.code, currencyCode: currency.code, timestamp: date.timeIntervalSince1970)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] rateValue in
                    self?.delegate?.didFetch(rateValue: rateValue, coin: coin, currency: currency, date: date)
                }, onError: { [weak self] _ in
                    self?.requestedTimestamps.removeAll { $0 == coin && $1 == date }
                })
                .disposed(by: ratesDisposeBag)
    }

}
