import UIKit
import SnapKit
import ThemeKit
import UIExtensions

class BackupPrivateKeyController: ThemeViewController {
    private let label = UILabel()
    private let keyContainer = UIView()
    private let copyButton: UIButton = .appYellow
    private let closeButton: UIButton = .appGray

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
//        title = "backup.private_key".localized
        title = "".localized
        
        keyContainer.backgroundColor = .themeGray50
        keyContainer.layer.cornerRadius = 4
        keyContainer.layer.masksToBounds = true
        
        label.numberOfLines = 0
        label.textColor = .themeWhite
        
        view.addSubview(keyContainer)
        keyContainer.addSubview(label)
        view.addSubview(copyButton)
        view.addSubview(closeButton)
        
        copyButton.addTarget(self, action: #selector(showCopied), for: .touchUpInside)
        copyButton.setTitle("button.copy".localized, for: .normal)
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        closeButton.setTitle("backup.close".localized, for: .normal)
        
        keyContainer.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin6x)
            maker.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(30)
        }
        
        label.snp.makeConstraints { maker in
            maker.edges.equalToSuperview().inset(CGFloat.margin2x)
        }
        
        copyButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin6x)
            maker.bottom.equalTo(closeButton.snp.top).offset(-20)
            maker.height.equalTo(CGFloat.heightButton)
        }
        
        closeButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin6x)
            maker.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-30)
            maker.height.equalTo(CGFloat.heightButton)
        }
    }
    
    func set(privateKey: String) {
        label.text = privateKey
    }
    
    @objc func showCopied() {
        UIPasteboard.general.string = label.text
        HudHelper.instance.showSuccess(title: "alert.copied".localized)
    }
    
    @objc func close() {
        self.dismiss(animated: true, completion: nil)
    }
}

class BackupWordsController: ThemeViewController {
    private let delegate: IBackupWordsViewDelegate

    private let collectionView: UICollectionView

    private let proceedButtonHolder = GradientView(gradientHeight: .margin4x, fromColor: UIColor.themeTyler.withAlphaComponent(0), toColor: .themeTyler)
    private let proceedButton: UIButton = .appYellow

    init(delegate: IBackupWordsViewDelegate) {
        self.delegate = delegate

        let layout = UICollectionViewFlowLayout()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)

        collectionView.register(BackupWordsCell.self, forCellWithReuseIdentifier: String(describing: BackupWordsCell.self))

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
//        title = "backup.private_key".localized

        view.addSubview(collectionView)

        view.addSubview(proceedButtonHolder)
        proceedButtonHolder.addSubview(proceedButton)

        collectionView.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin6x)
            maker.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).inset(CGFloat.heightBottomWrapperBar - CGFloat.margin8x)
        }
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.contentInset = UIEdgeInsets(top: CGFloat.margin3x, left: 0, bottom: CGFloat.margin8x, right: 0)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.alwaysBounceVertical = true
        collectionView.backgroundColor = .clear

        proceedButtonHolder.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
            maker.height.equalTo(CGFloat.heightBottomWrapperBar)
        }

        proceedButton.setTitle(delegate.isBackedUp ? "backup.close".localized : "button.next".localized, for: .normal)
        proceedButton.addTarget(self, action: #selector(nextDidTap), for: .touchUpInside)

        proceedButton.snp.makeConstraints { maker in
            maker.leading.trailing.bottom.equalToSuperview().inset(CGFloat.margin6x)
            maker.bottom.equalToSuperview().inset(CGFloat.margin8x)
            maker.height.equalTo(CGFloat.heightButton)
        }
    }

    private func words(for index: Int) -> [String] {
        Array(delegate.words.suffix(from: index * BackupWordsCell.maxWordsCount).prefix(BackupWordsCell.maxWordsCount))
    }

    @objc func nextDidTap() {
        delegate.didTapProceed()
    }

}

extension BackupWordsController: UICollectionViewDataSource {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        delegate.words.count / BackupWordsCell.maxWordsCount + (delegate.words.count % BackupWordsCell.maxWordsCount != 0 ? 1 : 0)
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: BackupWordsCell.self), for: indexPath)
    }

}

extension BackupWordsController: UICollectionViewDelegate {

    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? BackupWordsCell {
            cell.bind(startIndex: indexPath.row * BackupWordsCell.maxWordsCount + 1, words: words(for: indexPath.row))
        }
    }

}

extension BackupWordsController: UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: collectionView.width / 2, height: BackupWordsCell.heightFor(words: words(for: indexPath.row)))
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        0
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        CGFloat.margin6x
    }

}
