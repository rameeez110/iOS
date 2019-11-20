// Copyright DApps Platform Inc. All rights reserved.

import APIKit
import BigInt
import Eureka
import Foundation
import JSONRPCKit
import QRCodeReaderViewController
import TrustCore
import TrustKeystore
import UIKit

protocol SendViewControllerDelegate: class {
    func didPressConfirm(
        transaction: UnconfirmedTransaction,
        transfer: Transfer,
        in viewController: SendViewController
    )
}

class SendViewController: UIViewController { //: FormViewController {
    @IBOutlet var recipientAddressTextField: UITextField!
    @IBOutlet var amountTextField: UITextField!
    @IBOutlet var memoTextField: UITextField!

    @IBOutlet var sendButton: UIButton!

    private lazy var viewModel: SendViewModel = {
        let balance = Balance(value: transfer.type.token.valueBigInt)
        return .init(transfer: transfer, config: session.config, chainState: chainState, storage: storage, balance: balance)
    }()

    weak var delegate: SendViewControllerDelegate?
    struct Values {
        static let address = "address"
        static let amount = "amount"
    }

    let session: WalletSession
    let account: Account
    let transfer: Transfer
    let storage: TokensDataStore
    let chainState: ChainState
//    var addressRow: TextFloatLabelRow? {
//        return form.rowBy(tag: Values.address) as? TextFloatLabelRow
//    }
//    var amountRow: TextFloatLabelRow? {
//        return form.rowBy(tag: Values.amount) as? TextFloatLabelRow
//    }
    lazy var maxButton: UIButton = {
        let button = Button(size: .normal, style: .borderless)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(NSLocalizedString("send.max.button.title", value: "Max", comment: ""), for: .normal)
        button.addTarget(self, action: #selector(useMaxAmount), for: .touchUpInside)
        return button
    }()

    private var allowedCharacters: String = {
        let decimalSeparator = Locale.current.decimalSeparator ?? "."
        return "0123456789" + decimalSeparator
    }()

    private var data = Data()
    init(
        session: WalletSession,
        storage: TokensDataStore,
        account: Account,
        transfer: Transfer,
        chainState: ChainState
    ) {
        self.session = session
        self.account = account
        self.transfer = transfer
        self.storage = storage
        self.chainState = chainState
        super.init(nibName: "SendViewController", bundle: nil)
        title = viewModel.title
//        view.backgroundColor = viewModel.backgroundColor
        if #available(iOS 13.0, *) {
            // use the feature only available in iOS 9
            // for ex. UIStackView
            view.backgroundColor = UIColor.systemBackground
        } else {
            // or use some work around
            view.backgroundColor = viewModel.backgroundColor
        }

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: R.string.localizable.next(),
            style: .done,
            target: self,
            action: #selector(send)
        )

//        let section = Section(header: "", footer: viewModel.isFiatViewHidden() ? "" : viewModel.pairRateRepresantetion())
//        fields().forEach { cell in
//            section.append(cell)
//        }
//        form = Section()
//            +++ section
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.applyTintAdjustment()
//        self.view.backgroundColor = Colors.veryLightGray
        if #available(iOS 13.0, *) {
            // use the feature only available in iOS 9
            // for ex. UIStackView
            self.view.backgroundColor = UIColor.systemBackground
        } else {
            // or use some work around
            view.backgroundColor = Colors.veryLightGray
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
    }

    private func fields() -> [BaseRow] {
        return viewModel.views.map { field(for: $0) }
    }

    private func field(for type: SendViewType) -> BaseRow {
        switch type {
        case .address:
            return addressField()
        case .amount:
            return amountField()
        }
    }

    func setupUI() {
        sendButton.layer.cornerRadius = 10
        sendButton.clipsToBounds = true

        memoTextField.textAlignment = .left
        memoTextField.placeholder = "MEMO" // NSLocalizedString("send.recipientAddress.textField.placeholder", value: "Recipient Address", comment: "")
        memoTextField.rightViewMode = .always
        memoTextField.accessibilityIdentifier = "memo-field"

        let recipientRightView = AddressFieldView()
        recipientRightView.translatesAutoresizingMaskIntoConstraints = false
        recipientRightView.pasteButton.addTarget(self, action: #selector(pasteAction), for: .touchUpInside)
        recipientRightView.qrButton.addTarget(self, action: #selector(openReader), for: .touchUpInside)

        recipientAddressTextField.textAlignment = .left
        recipientAddressTextField.placeholder = NSLocalizedString("send.recipientAddress.textField.placeholder", value: "Recipient Address", comment: "")
        recipientAddressTextField.rightView = recipientRightView
        recipientAddressTextField.rightViewMode = .always
        recipientAddressTextField.accessibilityIdentifier = "amount-field"

        let fiatButton = Button(size: .normal, style: .borderless)
        fiatButton.translatesAutoresizingMaskIntoConstraints = false
        fiatButton.setTitle(viewModel.currentPair.right, for: .normal)
        fiatButton.addTarget(self, action: #selector(fiatAction), for: .touchUpInside)
        fiatButton.isHidden = viewModel.isFiatViewHidden()
        let amountRightView = UIStackView(arrangedSubviews: [
            maxButton,
            fiatButton,
        ])
        amountRightView.translatesAutoresizingMaskIntoConstraints = false
        amountRightView.distribution = .fill
        amountRightView.spacing = 1
        amountRightView.axis = .horizontal

        amountTextField.isCopyPasteDisabled = true
        amountTextField.textAlignment = .left
        amountTextField.delegate = self
        amountTextField.placeholder = "\(viewModel.currentPair.left) " + NSLocalizedString("send.amount.textField.placeholder", value: "Amount", comment: "")
        amountTextField.keyboardType = .decimalPad
        amountTextField.rightView = amountRightView
        amountTextField.rightViewMode = .always

        if #available(iOS 13.0, *) {
            // use the feature only available in iOS 9
            // for ex. UIStackView
            amountTextField.attributedPlaceholder = NSAttributedString(string: "\(self.viewModel.currentPair.left) " + NSLocalizedString("send.amount.textField.placeholder", value: "Amount", comment: ""),
                                                                       attributes: [NSAttributedString.Key.foregroundColor: UIColor.label])
            recipientAddressTextField.attributedPlaceholder = NSAttributedString(string: NSLocalizedString("send.recipientAddress.textField.placeholder", value: "Recipient Address", comment: ""),
                                                                                 attributes: [NSAttributedString.Key.foregroundColor: UIColor.label])
        }
    }

    func addressField() -> TextFloatLabelRow {
        let recipientRightView = AddressFieldView()
        recipientRightView.translatesAutoresizingMaskIntoConstraints = false
        recipientRightView.pasteButton.addTarget(self, action: #selector(pasteAction), for: .touchUpInside)
        recipientRightView.qrButton.addTarget(self, action: #selector(openReader), for: .touchUpInside)

        return AppFormAppearance.textFieldFloat(tag: Values.address) {
            $0.add(rule: EthereumAddressRule())
            $0.validationOptions = .validatesOnDemand
        }.cellUpdate { cell, _ in
            cell.textField.textAlignment = .left
            cell.textField.placeholder = NSLocalizedString("send.recipientAddress.textField.placeholder", value: "Recipient Address", comment: "")
            cell.textField.rightView = recipientRightView
            cell.textField.rightViewMode = .always
            cell.textField.accessibilityIdentifier = "amount-field"
        }
    }

    func amountField() -> TextFloatLabelRow {
        let fiatButton = Button(size: .normal, style: .borderless)
        fiatButton.translatesAutoresizingMaskIntoConstraints = false
        fiatButton.setTitle(viewModel.currentPair.right, for: .normal)
        fiatButton.addTarget(self, action: #selector(fiatAction), for: .touchUpInside)
        fiatButton.isHidden = viewModel.isFiatViewHidden()
        let amountRightView = UIStackView(arrangedSubviews: [
            maxButton,
            fiatButton,
        ])
        amountRightView.translatesAutoresizingMaskIntoConstraints = false
        amountRightView.distribution = .fill
        amountRightView.spacing = 1
        amountRightView.axis = .horizontal
        return AppFormAppearance.textFieldFloat(tag: Values.amount) {
            $0.add(rule: RuleRequired())
            $0.validationOptions = .validatesOnDemand
        }.cellUpdate { [weak self] cell, _ in
            cell.textField.isCopyPasteDisabled = true
            cell.textField.textAlignment = .left
            cell.textField.delegate = self
            cell.textField.placeholder = "\(self?.viewModel.currentPair.left ?? "") " + NSLocalizedString("send.amount.textField.placeholder", value: "Amount", comment: "")
            cell.textField.keyboardType = .decimalPad
            cell.textField.rightView = amountRightView
            cell.textField.rightViewMode = .always
        }
    }

    @IBAction func didTapSend() {
        send()
    }

    func clear() {
        recipientAddressTextField.text = ""
        amountTextField.text = ""
//        let fields = [addressRow, amountRow]
//        for field in fields {
//            field?.value = ""
//            field?.reload()
//        }
    }

    @objc func send() {
//        let errors = form.validate()
//        guard errors.isEmpty else { return }
//        let addressString = addressRow?.value?.trimmed ?? ""
        let amountString = viewModel.amount
        guard let address = EthereumAddress(string: self.recipientAddressTextField.text ?? "") else {
            return displayError(error: Errors.invalidAddress)
        }
        let parsedValue: BigInt? = {
            switch transfer.type {
            case .ether, .dapp:
                return EtherNumberFormatter.full.number(from: amountString, units: .ether)
            case let .token(token):
                return EtherNumberFormatter.full.number(from: amountString, decimals: token.decimals)
            }
        }()
        guard let value = parsedValue else {
            return displayError(error: SendInputErrors.wrongInput)
        }
        let transaction = UnconfirmedTransaction(
            transfer: transfer,
            value: value,
            to: address,
            data: data,
            gasLimit: .none,
            gasPrice: viewModel.gasPrice,
            nonce: .none
        )
        delegate?.didPressConfirm(transaction: transaction, transfer: transfer, in: self)
    }

    @objc func openReader() {
        let controller = QRCodeReaderViewController()
        controller.delegate = self
        present(controller, animated: true, completion: nil)
    }

    @objc func pasteAction() {
        guard let value = UIPasteboard.general.string?.trimmed else {
            return displayError(error: SendInputErrors.emptyClipBoard)
        }

        guard CryptoAddressValidator.isValidAddress(value) else {
            return displayError(error: Errors.invalidAddress)
        }
        recipientAddressTextField.text = value
//        addressRow?.value = value
//        addressRow?.reload()
        activateAmountView()
    }

    @objc func useMaxAmount() {
        amountTextField.text = viewModel.sendMaxAmount()
//        amountRow?.value = viewModel.sendMaxAmount()
        updatePriceSection()
//        amountRow?.reload()
    }

    @objc func fiatAction(sender: UIButton) {
        let swappedPair = viewModel.currentPair.swapPair()
        // New pair for future calculation we should swap pair each time we press fiat button.
        viewModel.currentPair = swappedPair
        // Update button title.
        sender.setTitle(viewModel.currentPair.right, for: .normal)
        // Hide max button
        maxButton.isHidden = viewModel.isMaxButtonHidden()
        // Reset amountRow value.
        amountTextField.text = ""
//        amountRow?.value = nil
//        amountRow?.reload()
        // Reset pair value.
        viewModel.pairRate = 0.0
        // Update section.
        updatePriceSection()
        // Set focuse on pair change.
        activateAmountView()
    }

    func activateAmountView() {
        recipientAddressTextField.becomeFirstResponder()
//        amountRow?.cell.textField.becomeFirstResponder()
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updatePriceSection() {
        // Update section only if fiat view is visible.
        guard !viewModel.isFiatViewHidden() else {
            return
        }
        // We use this section update to prevent update of the all section including cells.
        /* UIView.setAnimationsEnabled(false)
         tableView.beginUpdates()
         if let containerView = tableView.footerView(forSection: 1) {
             containerView.textLabel!.text = viewModel.pairRateRepresantetion()
             containerView.sizeToFit()
         }
         tableView.endUpdates()
         UIView.setAnimationsEnabled(true) */
    }
}

extension SendViewController: QRCodeReaderDelegate {
    func readerDidCancel(_ reader: QRCodeReaderViewController!) {
        reader.stopScanning()
        reader.dismiss(animated: true, completion: nil)
    }

    func reader(_ reader: QRCodeReaderViewController!, didScanResult result: String!) {
        reader.stopScanning()
        reader.dismiss(animated: true) { [weak self] in
            self?.activateAmountView()
        }

        guard let result = QRURLParser.from(string: result) else { return }
        recipientAddressTextField.text = result.address
//        addressRow?.value = result.address
//        addressRow?.reload()

        if let dataString = result.params["data"] {
            data = Data(hex: dataString.drop0x)
        } else {
            data = Data()
        }

        if let value = result.params["amount"] {
            amountTextField.text = value
//            amountRow?.value = value
            let amount = viewModel.decimalAmount(with: value)
            viewModel.updatePairPrice(with: amount)
        } else {
//            amountRow?.value = ""
            amountTextField.text = ""
            viewModel.pairRate = 0.0
        }
//        amountRow?.reload()
        updatePriceSection()
    }
}

extension SendViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let input = textField.text else {
            return true
        }
        // In this step we validate only allowed characters it is because of the iPad keyboard.
        let characterSet = NSCharacterSet(charactersIn: allowedCharacters).inverted
        let separatedChars = string.components(separatedBy: characterSet)
        let filteredNumbersAndSeparator = separatedChars.joined(separator: "")
        if string != filteredNumbersAndSeparator {
            return false
        }
        // This is required to prevent user from input of numbers like 1.000.25 or 1,000,25.
        if string == "," || string == "." || string == "'" {
            return !input.contains(string)
        }
        // Total amount of the user input.
        let stringAmount = (input as NSString).replacingCharacters(in: range, with: string)
        // Convert to deciaml for pair rate update.
        let amount = viewModel.decimalAmount(with: stringAmount)
        // Update of the pair rate.
        viewModel.updatePairPrice(with: amount)
        updatePriceSection()
        // Update of the total amount.
        viewModel.updateAmount(with: stringAmount)
        return true
    }
}
