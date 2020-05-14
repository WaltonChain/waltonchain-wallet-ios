import UIKit
import StorageKit

class KeychainKitDelegate {
    private let accountManager: IAccountManager
    private let walletManager: IWalletManager

    init(accountManager: IAccountManager, walletManager: IWalletManager) {
        self.accountManager = accountManager
        self.walletManager = walletManager
    }

    private func show(viewController: UIViewController) {
        UIApplication.shared.keyWindow?.set(newRootController: viewController)
    }

}

extension KeychainKitDelegate: IKeychainKitDelegate {

    func onInitialLock() {
        accountManager.clear()
        walletManager.clearWallets()
    }

    public func onLock() {
        show(viewController: NoPasscodeViewController())
    }

    public func onUnlock() {
        show(viewController: LaunchRouter.module())
    }

}
