// Copyright DApps Platform Inc. All rights reserved.

import UIKit
import StatefulViewController

protocol TokenViewControllerDelegate: class {
    func didPressRequest(for token: TokenObject, in controller: UIViewController)
    func didPressSend(for token: TokenObject, in controller: UIViewController)
    func didPressInfo(for token: TokenObject, in controller: UIViewController)
    func didPress(viewModel: TokenViewModel, transaction: Transaction, in controller: UIViewController)
}

enum TokenViewType: Int {
    case All = 0,Send,Recieve
}

final class TokenViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var fiatAmountLabel: UILabel!
    @IBOutlet weak var marketPriceLabel: UILabel!
    @IBOutlet weak var percentChange: UILabel!
    
    @IBOutlet weak var allView: UIView!
    @IBOutlet weak var sendView: UIView!
    @IBOutlet weak var recieveView: UIView!
    
    @IBOutlet weak var allButton: UIButton!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var recieveButton: UIButton!

    var selectedIndex = TokenViewType.All
    private let refreshControl = UIRefreshControl()

//    private var tableView = TransactionsTableView()

    private lazy var header: TokenHeaderView = {
        let view = TokenHeaderView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 242))
        return view
    }()

    private var insets: UIEdgeInsets {
        return UIEdgeInsets(top: header.frame.height + 100, left: 0, bottom: 0, right: 0)
    }

    private var viewModel: TokenViewModel

    weak var delegate: TokenViewControllerDelegate?

    init(viewModel: TokenViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "TokenViewController", bundle: nil)

        navigationItem.title = viewModel.title
        view.backgroundColor = .white
        tableView.tableFooterView = UIView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
//        tableView.tableHeaderView = header
        tableView.register(TransactionViewCell.self, forCellReuseIdentifier: TransactionViewCell.identifier)
//        view.addSubview(tableView)

        /*NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        ])*/

        refreshControl.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        tableView.addSubview(refreshControl)

        /*header.buttonsView.requestButton.addTarget(self, action: #selector(request), for: .touchUpInside)
        header.buttonsView.sendButton.addTarget(self, action: #selector(send), for: .touchUpInside)
        updateHeader()*/
        updateHeader()

        // TODO: Enable when finished
        if isDebug {
            //navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .organize, target: self, action: #selector(infoAction))
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        observToken()
        observTransactions()
        configTableViewStates()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupInitialViewState()
        fetch()
    }

    private func fetch() {
        startLoading()
        viewModel.fetch()
    }

    @objc func infoAction() {
        delegate?.didPressInfo(for: viewModel.token, in: self)
    }

    private func observToken() {
        viewModel.tokenObservation { [weak self] in
            self?.refreshControl.endRefreshing()
            self?.updateHeader()
            self?.endLoading()
        }
    }

    private func observTransactions() {
        viewModel.transactionObservation { [weak self] in
            self?.refreshControl.endRefreshing()
            self?.tableView.reloadData()
            self?.endLoading()
        }
    }

    private func updateHeader() {
        /*header*/self.imageView.kf.setImage(
            with: viewModel.imageURL,
            placeholder: viewModel.imagePlaceholder
        )
        self.amountLabel.text = viewModel.amount
        self.amountLabel.font = viewModel.amountFont
        self.amountLabel.textColor = viewModel.amountTextColor

        self.fiatAmountLabel.text = viewModel.totalFiatAmount
        self.fiatAmountLabel.font = viewModel.fiatAmountFont
        self.fiatAmountLabel.textColor = viewModel.fiatAmountTextColor

        self.marketPriceLabel.text = viewModel.marketPrice
        self.marketPriceLabel.textColor = viewModel.marketPriceTextColor
        self.marketPriceLabel.font = viewModel.marketPriceFont

        self.percentChange.text = viewModel.percentChange
        self.percentChange.textColor = viewModel.percentChangeColor
        self.percentChange.font = viewModel.percentChangeFont
    }

    @objc func pullToRefresh() {
        refreshControl.beginRefreshing()
        fetch()
    }

    @objc func send() {
        delegate?.didPressSend(for: viewModel.token, in: self)
    }

    @objc func request() {
        delegate?.didPressRequest(for: viewModel.token, in: self)
    }

    deinit {
        viewModel.invalidateObservers()
    }

    private func configTableViewStates() {
        errorView = ErrorView(insets: insets, onRetry: { [weak self] in
            self?.fetch()
        })
        loadingView = LoadingView(insets: insets)
        emptyView = TransactionsEmptyView(insets: insets)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension TokenViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections(type: self.selectedIndex)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TransactionViewCell.identifier, for: indexPath) as! TransactionViewCell
        cell.configure(viewModel: viewModel.cellViewModel(for: indexPath, type: self.selectedIndex))
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfItems(for: section, type: self.selectedIndex)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return SectionHeader(
            title: viewModel.titleForHeader(in: section, type: self.selectedIndex)
        )
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return StyleLayout.TableView.heightForHeaderInSection
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.didPress(viewModel: viewModel, transaction: viewModel.item(for: indexPath.row, section: indexPath.section, type: self.selectedIndex), in: self)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return TransactionsLayout.tableView.height//UITableView.automaticDimension
    }
}

extension TokenViewController: StatefulViewController {
    func hasContent() -> Bool {
        return viewModel.hasContent()
    }
}

extension TokenViewController {
    @IBAction func didTapSend(){
        self.send()
    }
    @IBAction func didTapRecieve(){
        self.request()
    }
    @IBAction func didTapAll(){
        self.selectedIndex = .All
        self.allView.isHidden = false
        self.sendView.isHidden = true
        self.recieveView.isHidden = true
        
        self.tableView.reloadData()
    }
    @IBAction func didTapSendItems(){
        self.selectedIndex = .Send
        self.allView.isHidden = true
        self.sendView.isHidden = false
        self.recieveView.isHidden = true
        
        self.tableView.reloadData()
    }
    @IBAction func didTapRecieveItems(){
        self.selectedIndex = .Recieve
        self.allView.isHidden = true
        self.sendView.isHidden = true
        self.recieveView.isHidden = false
        
        self.tableView.reloadData()
    }
}
