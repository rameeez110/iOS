// Copyright DApps Platform Inc. All rights reserved.
// Copyright Ether-1 Developers. All rights reserved.
// Copyright Xerom Developers. All rights reserved.

import Eureka
import TrustKeystore
import UIKit

protocol WalletInfoViewControllerDelegate: class {
    func didPress(item: WalletInfoType, in controller: WalletInfoViewController)
    func didPressSave(wallet: WalletInfo, fields: [WalletInfoField], in controller: WalletInfoViewController)
}

enum WalletInfoField {
    case name(String)
    case backup(Bool)
    case mainWallet(Bool)
    case balance(String)
}

final class WalletInfoViewController: FormViewController {
    lazy var viewModel: WalletInfoViewModel = {
        WalletInfoViewModel(wallet: wallet)
    }()

    var segmentRow: TextFloatLabelRow? {
        return form.rowBy(tag: Values.name)
    }

    let wallet: WalletInfo

    weak var delegate: WalletInfoViewControllerDelegate?

    private struct Values {
        static let name = "name"
    }

    lazy var saveBarButtonItem: UIBarButtonItem = {
        UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save))
    }()

    init(
        wallet: WalletInfo
    ) {
        self.wallet = wallet
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = viewModel.title
        navigationItem.rightBarButtonItem = saveBarButtonItem

        form +++ Section()

            <<< AppFormAppearance.textFieldFloat(tag: Values.name) {
                $0.add(rule: RuleRequired())
                $0.value = self.viewModel.name
            }.cellUpdate { [weak self] cell, _ in
                cell.textField.placeholder = self?.viewModel.nameTitle
                cell.textField.rightViewMode = .always
            }

        for types in viewModel.sections {
            let newSection = Section(footer: types.footer ?? "")
            for type in types.rows {
                newSection.append(link(item: type))
            }
            form +++ newSection
        }
    }

    private func link(
        item: WalletInfoType
    ) -> ButtonRowRow {
        let button = ButtonRowRow(item.title) {
            $0.title = item.title
            $0.value = item
        }.onCellSelection { [weak self] _, row in
            guard let `self` = self, let item = row.value else { return }
            self.delegate?.didPress(item: item, in: self)
        }.cellSetup { cell, _ in
            cell.imageView?.image = item.image
        }.cellUpdate { cell, _ in
            cell.textLabel?.textAlignment = .left
            cell.textLabel?.textColor = .black
            cell.accessoryType = .disclosureIndicator
        }
        return button
    }

    @objc func save() {
        let name = segmentRow?.value ?? ""
        delegate?.didPressSave(wallet: wallet, fields: [.name(name)], in: self)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

typealias ButtonRowRow = ButtonRowOf<WalletInfoType>
