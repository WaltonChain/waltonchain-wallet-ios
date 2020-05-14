import UIKit
import SnapKit
import SectionsTableView
import ThemeKit
import CurrencyKit
import PinKit

class SendConfirmationViewController: ThemeViewController, SectionsDataSource {
    private let confirmationFieldHeight: CGFloat = 24

    private let delegate: ISendConfirmationViewDelegate

    private let tableView = SectionsTableView(style: .grouped)
    private var rows = [RowProtocol]()
    private var noMemo = true
    private var cellPaddingAdded = false

    private let decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ""
        return formatter
    }()

    init(delegate: ISendConfirmationViewDelegate) {
        self.delegate = delegate

        super.init()
    }

    @objc func onClose() {
//        delegate.onClose()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "send.confirmation.title".localized

        tableView.registerCell(forClass: SendConfirmationAmountCell.self)
        tableView.registerCell(forClass: SendConfirmationReceiverCell.self)
        tableView.registerCell(forClass: SendConfirmationMemoCell.self)
        tableView.registerCell(forClass: SendConfirmationFieldCell.self)
        tableView.registerCell(forClass: SendButtonCell.self)
        tableView.sectionDataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.delaysContentTouches = false
        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .done, target: self, action: #selector(onTapCancel))

        delegate.viewDidLoad()
    }

    @objc private func onTapCancel() {
        delegate.onCancelClicked()
    }

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()
        var rows = [RowProtocol]()
        rows.append(contentsOf: self.rows)
        let sendButtonRow = Row<SendButtonCell>(id: "send_row", height: 74, bind: { [weak self] cell, _ in
            cell.bind { [weak self] in
                self?.onSendTap()
            }
        })
        rows.append(sendButtonRow)
        sections.append(Section(id: "confirmation_section", rows: rows))
        return sections
    }

    private func onSendTap() {
        if App.shared.pinKit.isPinSet {
            present(App.shared.pinKit.unlockPinModule(delegate: self, enableBiometry: false, presentationStyle: .simple, cancellable: true), animated: true)
        } else {
            present(App.shared.pinKit.setPinModule(delegate: self), animated: true)
        }
    }

    private func onHashTap(receiver: String) {
        delegate.onCopy(receiver: receiver)
    }

    private func format(coinValue: CoinValue) -> String? {
        decimalFormatter.maximumFractionDigits = min(coinValue.coin.decimal, 8)
        return decimalFormatter.string(from: coinValue.value as NSNumber)
    }

    private func format(currencyValue: CurrencyValue) -> String? {
        decimalFormatter.maximumFractionDigits = currencyValue.currency.decimal
        return decimalFormatter.string(from: currencyValue.value as NSNumber)
    }

}

extension SendConfirmationViewController: ISendConfirmationView {

    func show(viewItem: SendConfirmationAmountViewItem) {
        let primaryRow = Row<SendConfirmationAmountCell>(id: "send_primary_row", height: 72, bind: { cell, _ in
            cell.bind(primaryAmountInfo: viewItem.primaryInfo, secondaryAmountInfo: viewItem.secondaryInfo)
        })
        let receiverRow = Row<SendConfirmationReceiverCell>(id: "send_receiver_row", height: SendConfirmationReceiverCell.height(forContainerWidth: view.bounds.width, text: viewItem.receiver), bind: { [weak self] cell, _ in
            cell.bind(receiver: viewItem.receiver, last: self?.noMemo ?? false) { [weak self] in
                self?.onHashTap(receiver: viewItem.receiver)
            }
        })
        rows.append(primaryRow)
        rows.append(receiverRow)
    }

    func show(viewItem: SendConfirmationMemoViewItem) {
        guard !viewItem.memo.isEmpty else {
            return
        }
        noMemo = false
        let row = Row<SendConfirmationMemoCell>(id: "send_memo_row", height: .heightSingleLineCell, bind: { cell, _ in
            cell.bind(memo: viewItem.memo)
        })

        rows.append(row)
    }

    private var additionalPadding: CGFloat {
        cellPaddingAdded ? 0 : .margin1x
    }

    func show(viewItem: SendConfirmationFeeViewItem) {
        let formattedPrimary: String?
        var formattedSecondary: String? = nil

        switch viewItem.primaryInfo {
        case .coinValue(let coinValue):
            formattedPrimary = ValueFormatter.instance.format(coinValue: coinValue)
        case .currencyValue(let currencyValue):
            formattedPrimary = ValueFormatter.instance.format(currencyValue: currencyValue)
        }

        if let secondaryInfo = viewItem.secondaryInfo {
            switch secondaryInfo {
            case .coinValue(let coinValue):
                formattedSecondary = ValueFormatter.instance.format(coinValue: coinValue)
            case .currencyValue(let currencyValue):
                formattedSecondary = ValueFormatter.instance.format(currencyValue: currencyValue)
            }
        }

        guard let primaryText = formattedPrimary else { return }
        let text = [primaryText, formattedSecondary != nil ? "|" : nil, formattedSecondary].compactMap { $0 }.joined(separator: " ")

        let row = Row<SendConfirmationFieldCell>(id: "send_fee_row", height: confirmationFieldHeight + additionalPadding, bind: { cell, _ in
            cell.bind(title: "send.fee".localized, text: text)
        })
        cellPaddingAdded = true

        rows.append(row)
    }

    func show(viewItem: SendConfirmationTotalViewItem) {
        let formattedPrimary: String?

        switch viewItem.primaryInfo {
        case .coinValue(let coinValue):
            formattedPrimary = ValueFormatter.instance.format(coinValue: coinValue)
        case .currencyValue(let currencyValue):
            formattedPrimary = ValueFormatter.instance.format(currencyValue: currencyValue)
        }

        guard let primaryText = formattedPrimary else { return }

        let row = Row<SendConfirmationFieldCell>(id: "send_total_row", height: confirmationFieldHeight + additionalPadding, bind: { cell, _ in
            cell.bind(title: "send.confirmation.total".localized, text: primaryText)
        })
        cellPaddingAdded = true

        rows.append(row)
    }

    func show(viewItem: SendConfirmationDurationViewItem) {
        let row = Row<SendConfirmationFieldCell>(id: "send_duration_row", height: confirmationFieldHeight + additionalPadding, bind: { cell, _ in
            cell.bind(title: "send.tx_duration".localized, text: viewItem.timeInterval.map { "send.duration.within".localized($0.approximateHoursOrMinutes) } ?? "send.duration.instant".localized)
        })
        cellPaddingAdded = true

        rows.append(row)
    }

    func show(viewItem: SendConfirmationLockUntilViewItem) {
        let row = Row<SendConfirmationFieldCell>(id: "send_lock_until_row", height: confirmationFieldHeight + additionalPadding, bind: { cell, _ in
            cell.bind(title: "send.lock_time".localized, text: viewItem.lockValue.localized)
        })
        cellPaddingAdded = true

        rows.append(row)
    }

    func buildData() {
        tableView.reload()
    }

    func showCopied() {
        HudHelper.instance.showSuccess(title: "alert.copied".localized)
    }

}

extension SendConfirmationViewController: IUnlockDelegate, ISetPinDelegate {
    func didCancelSetPin() {

    }
    
    func onUnlock() {
        delegate.onSendClicked()
    }
    
    func onCancelUnlock() {
        
    }
    
    func didSetPin() {
        
    }
}
