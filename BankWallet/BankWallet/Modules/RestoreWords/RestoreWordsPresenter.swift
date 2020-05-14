import ThemeKit

class RestoreWordsPresenter {
    weak var view: IRestoreWordsView?

    private let mode: RestoreRouter.PresentationMode
    private let router: IRestoreWordsRouter
    private var wordsManager: IWordsManager
    private let appConfigProvider: IAppConfigProvider

    let wordsCount: Int

    init(mode: RestoreRouter.PresentationMode, router: IRestoreWordsRouter, wordsCount: Int, wordsManager: IWordsManager, appConfigProvider: IAppConfigProvider) {
        self.mode = mode
        self.router = router
        self.wordsCount = wordsCount
        self.wordsManager = wordsManager
        self.appConfigProvider = appConfigProvider
    }

    private func notify(words: [String]) {
        let accountType: AccountType = .mnemonic(words: words, salt: nil)

        switch mode {
        case .pushed: router.notifyRestored(accountType: accountType)
        case .presented: router.dismissAndNotify(accountType: accountType)
        }
    }
    
    private func notify(privateKey: String) {
        let accountType: AccountType = .privateKey(data: Data(hexString: privateKey)!)
        switch mode {
        case .pushed: router.notifyRestored(accountType: accountType)
        case .presented: router.dismissAndNotify(accountType: accountType)
        }
    }
}

extension RestoreWordsPresenter: IRestoreWordsViewDelegate {

    func viewDidLoad() {
        if mode == .presented {
            view?.showCancelButton()
        }

        view?.showRestoreButton()
        view?.show(defaultWords: appConfigProvider.defaultWords(count: wordsCount))
    }

    func didTapRestore(words: [String]) {
        do {
            try wordsManager.validate(words: words, requiredWordsCount: wordsCount)
            notify(words: words)
        } catch {
            if let pk = words.first, words.count == 1 {
                notify(privateKey: pk)
            } else {
                view?.show(error: error)
            }
        }
    }

    func didTapCancel() {
        router.dismiss()
    }

}
