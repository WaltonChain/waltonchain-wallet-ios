class RestoreEosPresenter {
    weak var view: IRestoreEosView?

    private let mode: RestoreRouter.PresentationMode
    private let interactor: IRestoreEosInteractor
    private let router: IRestoreEosRouter

    private var state: RestoreEosPresenterState

    init(mode: RestoreRouter.PresentationMode, interactor: IRestoreEosInteractor, router: IRestoreEosRouter, state: RestoreEosPresenterState) {
        self.mode = mode
        self.interactor = interactor
        self.router = router
        self.state = state
    }

    private func onEnter(account: String?) {
        state.account = account
        view?.set(account: account)
    }

    private func onEnter(key: String?) {
        state.privateKey = key
        view?.set(key: key)
    }

    private func omitReturns(string: String) -> String {
        return string.replacingOccurrences(of: "\n", with: " ")
    }

}

extension RestoreEosPresenter: IRestoreEosViewDelegate {

    func viewDidLoad() {
        if mode == .presented {
            view?.showCancelButton()
        }

        let (account, activePrivateKey) = interactor.defaultCredentials
        onEnter(account: account)
        onEnter(key: activePrivateKey)
    }

    func onPasteAccountClicked() {
        if let account = interactor.valueFromPasteboard {
            onEnter(account: omitReturns(string: account))
        }
    }

    func onChange(account: String?) {
        onEnter(account: account)
    }

    func onDeleteAccount() {
        onEnter(account: nil)
    }

    func onPasteKeyClicked() {
        if let key = interactor.valueFromPasteboard {
            onEnter(key: omitReturns(string: key))
        }
    }

    func onScan(key: String) {
        onEnter(key: key)
    }

    func onDeleteKey() {
        onEnter(key: nil)
    }

    func didTapCancel() {
        router.dismiss()
    }

    func didTapDone() {
        let account = (state.account ?? "").trimmingCharacters(in: .whitespaces).lowercased()
        let privateKey = (state.privateKey ?? "").trimmingCharacters(in: .whitespaces)

        do {
            try interactor.validate(account: account)
            try interactor.validate(privateKey: privateKey)

            let accountType: AccountType = .eos(account: account, activePrivateKey: privateKey)

            switch mode {
            case .pushed: router.notifyRestored(accountType: accountType)
            case .presented: router.dismissAndNotify(accountType: accountType)
            }
        } catch {
            view?.show(error: error)
        }
    }

}

extension RestoreEosPresenter: IRestoreEosInteractorDelegate {
}
