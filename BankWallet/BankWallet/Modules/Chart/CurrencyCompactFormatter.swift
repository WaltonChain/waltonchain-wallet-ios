import Foundation
import CurrencyKit

class CurrencyCompactFormatter {
    private static let postfixes = ["chart.market_cap.thousand", "chart.market_cap.million", "chart.market_cap.billion", "chart.market_cap.trillion"]
    public static let instance = CurrencyCompactFormatter()

    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 1
        return formatter
    }()

    private static func compactData(value: Decimal) -> (value: Decimal, postfix: String?) {
        let ten: Decimal = 10

        var index = 1
        var power: Decimal = 1000
        while value >= power {
            power = pow(ten, (index + 1) * 3)
            index += 1
            if index > postfixes.count {
                break
            }
        }
        let postfix: String? = index < 2 ? nil : CurrencyCompactFormatter.postfixes[index - 2]
        return (value: value / pow(ten, (index - 1) * 3), postfix: postfix)
    }

    public func format(currencyValue: CurrencyValue?) -> String? {
        guard let currencyValue = currencyValue else {
            return nil
        }
        let data = CurrencyCompactFormatter.compactData(value: currencyValue.value)

        currencyFormatter.currencyCode = currencyValue.currency.code
        currencyFormatter.currencySymbol = currencyValue.currency.symbol

        guard let formattedValue = currencyFormatter.string(from: data.value as NSNumber) else {
            return nil
        }
        return data.postfix?.localized(formattedValue) ?? formattedValue
    }

}
