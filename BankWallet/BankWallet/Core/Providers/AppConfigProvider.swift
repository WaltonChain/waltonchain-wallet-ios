import Foundation

class AppConfigProvider: IAppConfigProvider {
    let ipfsId = "QmXTJZBMMRmBbPun6HFt3tmb3tfYF2usLPxFoacL7G5uMX"
    let ipfsGateways = [
        "https://ipfs-ext.horizontalsystems.xyz",
        "https://ipfs.io"
    ]

    let companyWebPageLink = "https://horizontalsystems.io"
    let appWebPageLink = "https://app.waltonchain.org/app-h5/wtc_download"
    let reportEmail = "wallet@waltonchain.org"
    let telegramWalletHelperGroup = "Waltonchain_official"
    let telegramDevelopersGroup = "Waltonchain_development"

    let reachabilityHost = "ipfs.horizontalsystems.xyz"

    var testMode: Bool {
        Bundle.main.object(forInfoDictionaryKey: "TestMode") as? String == "true"
    }

    var officeMode: Bool {
        Bundle.main.object(forInfoDictionaryKey: "OfficeMode") as? String == "true"
    }

    func defaultWords(count: Int) -> [String] {
        guard let wordsString = Bundle.main.object(forInfoDictionaryKey: "DefaultWords\(count)") as? String else {
            return []
        }

        return wordsString.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
    }

    var defaultEosCredentials: (String, String) {
        guard let account = Bundle.main.object(forInfoDictionaryKey: "DefaultEosAccount") as? String, let privateKey = Bundle.main.object(forInfoDictionaryKey: "DefaultEosPrivateKey") as? String else {
            return ("", "")
        }

        return (account, privateKey)
    }

    var infuraCredentials: (id: String, secret: String?) {
        let id = (Bundle.main.object(forInfoDictionaryKey: "InfuraProjectId") as? String) ?? ""
        let secret = Bundle.main.object(forInfoDictionaryKey: "InfuraProjectSecret") as? String
        return (id: id, secret: secret)
    }

    var btcCoreRpcUrl: String {
        (Bundle.main.object(forInfoDictionaryKey: "BtcCoreRpcUrl") as? String) ?? ""
    }

    var etherscanKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "EtherscanApiKey") as? String) ?? ""
    }

    var disablePinLock: Bool {
        Bundle.main.object(forInfoDictionaryKey: "DisablePinLock") as? String == "true"
    }

    let currencyCodes: [String] = ["CNY", "USD", "EUR", "GBP", "JPY"]

    var featuredCoins: [Coin] {
        [
            coins[0],
        ]
    }

    let coins = [
        Coin(id: "WTC",       title: "Waltonchain",              code: "WTC",     decimal: 18, type: .ethereum),
        Coin(id: "WTA",      title: "Waltonchain Autonomy",              code: "WTA",    decimal: 18,  type: CoinType(erc20Address: "0x668df218d073f413Ed2FCEa0D48CfbFd59C030Ae")),
    ]

}
