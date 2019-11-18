// Copyright DApps Platform Inc. All rights reserved.

import Foundation
import RealmSwift
import Result
import TrustCore
import UIKit

protocol TokensViewControllerDelegate: class {
    func didPressAddToken(in viewController: UIViewController)
    func didSelect(token: TokenObject, in viewController: UIViewController)
    func didRequest(token: TokenObject, in viewController: UIViewController)
    func didTapCreateWallet(in viewController: UIViewController)
}

final class TokensViewController: UIViewController {
    fileprivate var viewModel: TokensViewModel

    lazy var header: TokensHeaderView = {
        let header = TokensHeaderView(frame: .zero)
        header.amountLabel.text = viewModel.headerBalance
        header.amountLabel.textColor = viewModel.headerBalanceTextColor
        header.backgroundColor = viewModel.headerBackgroundColor
        header.amountLabel.font = viewModel.headerBalanceFont
        if #available(iOS 13.0, *) {
            // use the feature only available in iOS 9
            // for ex. UIStackView
            header.amountLabel.textColor = UIColor.label
            header.backgroundColor = UIColor.systemBackground
        }
        header.frame.size = header.systemLayoutSizeFitting(UIView.layoutFittingExpandedSize)
        return header
    }()

    lazy var footer: TokensFooterView = {
        let footer = TokensFooterView(frame: .zero)
        footer.textLabel.text = "Empty Wallet!" // viewModel.footerTitle
        footer.textLabel.font = viewModel.footerTextFont
        footer.textLabel.textColor = viewModel.footerTextColor
        if #available(iOS 13.0, *) {
            // use the feature only available in iOS 9
            // for ex. UIStackView
            footer.textLabel.textColor = UIColor.label
        }
        footer.frame.size = footer.systemLayoutSizeFitting(UIView.layoutFittingExpandedSize)
        footer.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(missingToken))
        )
        footer.createButton.addTarget(self, action: #selector(createWallet), for: .touchUpInside)
        return footer
    }()

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorStyle = .none
        tableView.separatorColor = UIColor.clear // StyleLayout.TableView.separatorColor
//        tableView.backgroundColor = Colors.veryLightGray//.white
        if #available(iOS 13.0, *) {
            // use the feature only available in iOS 9
            // for ex. UIStackView
            tableView.backgroundColor = UIColor.systemBackground
        } else {
            // or use some work around
            tableView.backgroundColor = Colors.veryVeryLightGray
        }
//        tableView.register(TokenViewCell.self, forCellReuseIdentifier: TokenViewCell.identifier)
        tableView.tableHeaderView = header
        tableView.tableFooterView = footer
        tableView.addSubview(refreshControl)
        tableView.register(UINib(nibName: "TokenViewCell", bundle: nil), forCellReuseIdentifier: "TokenViewCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 65
        return tableView
    }()

    let refreshControl = UIRefreshControl()
    weak var delegate: TokensViewControllerDelegate?
    var etherFetchTimer: Timer?
    let intervalToETHRefresh = 10.0

    lazy var fetchClosure: () -> Void = {
        debounce(delay: .seconds(7), action: { [weak self] () in
            self?.viewModel.fetch()
        })
    }()

    init(
        viewModel: TokensViewModel
    ) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.viewModel.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        refreshControl.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        sheduleBalanceUpdate()
        NotificationCenter.default.addObserver(self, selector: #selector(TokensViewController.resignActive), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(TokensViewController.didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        startTokenObservation()
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
        footer.textLabel.text = "Empty Wallet!" // viewModel.footerTitle
        fetch(force: true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.applyTintAdjustment()

        if viewModel.tokens.isEmpty {
            footer.emptyWalletImageView.isHidden = false
            footer.textLabel.isHidden = false
            footer.createButton.isHidden = false
        } else {
            footer.emptyWalletImageView.isHidden = true
            footer.textLabel.isHidden = true
            footer.createButton.isHidden = true
        }
        tableView.tableFooterView = footer
//        tableView.reloadData()
    }

    @objc func pullToRefresh() {
        refreshControl.beginRefreshing()
        fetch(force: true)
    }

    func fetch(force: Bool = false) {
        if force {
            viewModel.fetch()
        } else {
            fetchClosure()
        }
    }

    @objc func createWallet() {
        delegate?.didTapCreateWallet(in: self)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func refreshHeaderView() {
        header.amountLabel.text = viewModel.headerBalance
    }

    @objc func missingToken() {
        delegate?.didPressAddToken(in: self)
    }

    private func startTokenObservation() {
        viewModel.setTokenObservation { [weak self] (changes: RealmCollectionChange) in
            guard let strongSelf = self else { return }
            let tableView = strongSelf.tableView
            switch changes {
            case .initial:
                tableView.reloadData()
            case .update:
                self?.tableView.reloadData()
            case .error: break
            }
            strongSelf.refreshControl.endRefreshing()
            self?.refreshHeaderView()
        }
    }

    @objc func resignActive() {
        etherFetchTimer?.invalidate()
        etherFetchTimer = nil
        stopTokenObservation()
    }

    @objc func didBecomeActive() {
        sheduleBalanceUpdate()
        startTokenObservation()
    }

    private func sheduleBalanceUpdate() {
        guard etherFetchTimer == nil else { return }
        etherFetchTimer = Timer.scheduledTimer(timeInterval: intervalToETHRefresh, target: BlockOperation { [weak self] in
            self?.viewModel.updatePendingTransactions()
        }, selector: #selector(Operation.main), userInfo: nil, repeats: true)
    }

    private func stopTokenObservation() {
        viewModel.invalidateTokensObservation()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        resignActive()
        stopTokenObservation()
    }
}

extension TokensViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let token = viewModel.item(for: indexPath)
        delegate?.didSelect(token: token, in: self)
    }

    @available(iOS 11.0, *)
    func tableView(_: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let token = viewModel.item(for: indexPath)
        let deleteAction = UIContextualAction(style: .normal, title: R.string.localizable.transactionsReceiveButtonTitle()) { _, _, handler in
            self.delegate?.didRequest(token: token, in: self)
            handler(true)
        }
        deleteAction.backgroundColor = Colors.darkRed
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        return configuration
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        return UITableView.automaticDimension // TokensLayout.tableView.height
    }
}

extension TokensViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TokenViewCell.identifier, for: indexPath) as! TokenViewCell
//        cell.isExclusiveTouch = true
        return cell
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return viewModel.tokens.count
    }

    func tableView(_: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let tokenViewCell = cell as? TokenViewCell else { return }
        tokenViewCell.configure(viewModel: viewModel.cellViewModel(for: indexPath))
    }
}

extension TokensViewController: TokensViewModelDelegate {
    func refresh() {
        tableView.reloadData()
        refreshHeaderView()
    }
}

extension TokensViewController: Scrollable {
    func scrollOnTop() {
        tableView.scrollOnTop()
    }
}
