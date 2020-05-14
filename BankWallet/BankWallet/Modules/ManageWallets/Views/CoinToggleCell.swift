import UIKit
import SnapKit
import ThemeKit

class CoinToggleCell: ThemeCell {
    private let coinImageView = CoinIconImageView()
    private let titleLabel = UILabel()
    private let coinLabel = UILabel()
    private let blockchainBadgeView = BadgeView()
    private let toggleView = UISwitch()
    private let addImageView = UIImageView()

    private var onToggle: ((Bool) -> ())?

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(coinImageView)
        coinImageView.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.equalToSuperview().offset(CGFloat.margin4x)
        }

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(self.coinImageView.snp.trailing).offset(CGFloat.margin4x)
            maker.top.equalToSuperview().offset(CGFloat.margin2x)
        }

        titleLabel.textColor = .themeOz
        titleLabel.font = .body

        contentView.addSubview(coinLabel)
        coinLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(self.titleLabel)
            maker.top.equalTo(self.titleLabel.snp.bottom).offset(3)
        }

        coinLabel.textColor = .themeGray
        coinLabel.font = .body

        contentView.addSubview(blockchainBadgeView)
        blockchainBadgeView.snp.makeConstraints { maker in
            maker.leading.equalTo(coinLabel.snp.trailing).offset(CGFloat.margin1x)
            maker.centerY.equalTo(coinLabel.snp.centerY)
        }

        contentView.addSubview(toggleView)
        toggleView.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().offset(-CGFloat.margin4x)
            maker.centerY.equalToSuperview()
        }

        toggleView.tintColor = .themeSteel20
        toggleView.addTarget(self, action: #selector(switchChanged), for: .valueChanged)

        contentView.addSubview(addImageView)
        addImageView.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().offset(-CGFloat.margin4x)
            maker.centerY.equalToSuperview()
        }

        addImageView.image = UIImage(named: "Edit Coins Icon")?.withRenderingMode(.alwaysTemplate)
        addImageView.tintColor = .themeGray
    }

    @objc func switchChanged() {
        onToggle?(toggleView.isOn)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func bind(coin: Coin, state: CoinToggleViewItemState, last: Bool, onToggle: ((Bool) -> ())? = nil) {
        switch state {
        case .toggleHidden:
            super.bind(last: last)

            addImageView.isHidden = false
            toggleView.isHidden = true
            selectionStyle = .default
        case .toggleVisible(let enabled):
            super.bind(last: last)

            addImageView.isHidden = true
            toggleView.isHidden = false
            toggleView.setOn(enabled, animated: false)
            selectionStyle = .none
        }

        coinImageView.bind(coin: coin)
        titleLabel.text = coin.title
        coinLabel.text = coin.code

//        if let blockchainType = coin.type.blockchainType {
//            blockchainBadgeView.isHidden = false
//            blockchainBadgeView.set(text: blockchainType)
//        } else {
//            blockchainBadgeView.isHidden = true
//        }
        /// 隐藏添加币种时的ERC20
        blockchainBadgeView.isHidden = true


        self.onToggle = onToggle
    }

}
