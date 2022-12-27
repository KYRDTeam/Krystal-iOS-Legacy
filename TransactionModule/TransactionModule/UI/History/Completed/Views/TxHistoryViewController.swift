//
//  TxHistoryViewController.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 21/12/2022.
//

import UIKit
import Utilities
import SkeletonView
import DesignSystem
import TokenModule
import BaseModule
import AppState
import Dependencies

class TxHistoryViewController: BaseWalletOrientedViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchField: UITextField!
    @IBOutlet weak var selectedSearchView: UIView!
    @IBOutlet weak var searchTokenLabel: UILabel!
    @IBOutlet weak var searchContainerView: UIView!
    @IBOutlet weak var emptyView: UIView!
    
    private let refreshControl = UIRefreshControl()
    var tokenSelectPopup: TokenSelectPopup?
    var onSwapTapped: (() -> ())?
    
    var viewModel: TxHistoryViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
        observeNotifications()
        bindViewModel()
        viewModel.load(shouldReset: true)
    }
    
    func setupViews() {
        view.isUserInteractionDisabledWhenSkeletonIsActive = true
        searchContainerView.isHidden = true
        selectedSearchView.isHidden = true
        setupSearchBar()
        setupTableView()
        setupRefreshControl()
        setupTokenSelectPopup()
    }
    
    func setupSearchBar() {
        searchField.setPlaceholder(text: "Filter by token", color: AppTheme.current.secondaryTextColor)
        searchField.delegate = self
    }
    
    func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.registerCellNib(TxHeaderCell.self)
        tableView.registerCellNib(TxTokenCell.self)
        tableView.registerCellNib(TxFooterCell.self)
        tableView.registerCellNib(TxSkeletonCell.self)
        tableView.registerCellNib(TxDateCell.self)
        tableView.registerCellNib(TxNFTCell.self)
        tableView.tableHeaderView = .init(frame: .init(x: 0, y: 0, width: 0, height: CGFloat.leastNonzeroMagnitude))
        tableView.contentInset = .init(top: 8, left: 0, bottom: 0, right: 0)
        if #available(iOS 10.0, *) {
            tableView.refreshControl = refreshControl
        } else {
            tableView.addSubview(refreshControl)
        }
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
    }
    
    func setupTokenSelectPopup() {
        let viewModel = TokenSelectViewModel()
        tokenSelectPopup = TokenSelectPopup.instantiateFromNib()
        tokenSelectPopup!.viewModel = viewModel
        
        tokenSelectPopup!.view.frame = searchContainerView.bounds
        searchContainerView.addSubview(tokenSelectPopup!.view)
        addChild(tokenSelectPopup!)
        tokenSelectPopup!.didMove(toParent: self)
        tokenSelectPopup!.onBackgroundTapped = { [weak self] in
            self?.searchField.resignFirstResponder()
            self?.searchField.text = nil
            self?.searchContainerView.isHidden = true
        }
        tokenSelectPopup!.onSelectToken = { [weak self] token in
            self?.searchField.resignFirstResponder()
            self?.searchField.text = nil
            self?.viewModel.selectedFilterToken = token
            self?.searchTokenLabel.text = token.symbol
            self?.searchContainerView.isHidden = true
            self?.selectedSearchView.isHidden = false
            self?.emptyView.isHidden = true
            self?.showSkeletonLoading()
            self?.viewModel.load(shouldReset: true)
        }
    }
    
    func resetFilterTokenUI() {
        self.viewModel.selectedFilterToken = nil
        self.searchField.resignFirstResponder()
        self.searchField.text = nil
        self.searchTokenLabel.text = nil
        self.searchContainerView.isHidden = true
        self.selectedSearchView.isHidden = true
    }
    
    @objc func refreshData() {
        DispatchQueue.main.async {
            self.tableView.beginUpdates()
            self.refreshControl.endRefreshing()
            self.tableView.endUpdates()
        }
        emptyView.isHidden = true
        showSkeletonLoading()
        viewModel.load(shouldReset: true)
    }
    
    func appDidSwitchChain() {
        resetFilterTokenUI()
        emptyView.isHidden = true
        showSkeletonLoading()
        viewModel.load(shouldReset: true)
    }
    
    func appDidSwitchAddress() {
        resetFilterTokenUI()
        emptyView.isHidden = true
        showSkeletonLoading()
        viewModel.load(shouldReset: true)
    }
    
    override func onAppSwitchChain() {
        viewModel.currentChain = AppState.shared.currentChain
        appDidSwitchChain()
    }
    
    override func onAppSelectAllChain() {
        viewModel.currentChain = .all
        appDidSwitchChain()
    }
    
    override func onAppSwitchAddress(switchChain: Bool) {
        appDidSwitchAddress()
    }
    
    func bindViewModel() {
        emptyView.isHidden = true
        showSkeletonLoading()
        viewModel.onRowsUpdated = { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.hideSkeletonLoading()
                self.tableView.reloadData()
                self.emptyView.isHidden = !self.viewModel.rows.isEmpty
            }
        }
    }
    
    func setupRefreshControl() {
        refreshControl.tintColor = UIColor.white.withAlphaComponent(0.5)
    }
    
    func showSkeletonLoading() {
        let gradient = SkeletonGradient(baseColor: AppTheme.current.sectionBackgroundColor)
        view.showAnimatedGradientSkeleton(usingGradient: gradient)
    }

    func hideSkeletonLoading() {
        view.hideSkeleton()
    }
    
    @IBAction func searchCloseTapped(_ sender: Any) {
        selectedSearchView.isHidden = true
        viewModel.selectedFilterToken = nil
        emptyView.isHidden = true
        showSkeletonLoading()
        viewModel.load(shouldReset: true)
    }
    
    @IBAction func swapTapped(_ sender: Any) {
        parent?.navigationController?.popViewController(animated: true)
        AppDependencies.router.openSwap()
    }

}

extension TxHistoryViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.rows.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = viewModel.rows[indexPath.row]
        switch row {
        case .header(let viewModel):
            let cell = tableView.dequeueReusableCell(TxHeaderCell.self, indexPath: indexPath)!
            cell.configure(viewModel: viewModel)
            cell.selectionStyle = .none
            return cell
        case .tokenChange(let viewModel):
            let cell = tableView.dequeueReusableCell(TxTokenCell.self, indexPath: indexPath)!
            cell.configure(viewModel: viewModel)
            cell.selectionStyle = .none
            return cell
        case .footer(let viewModel):
            let cell = tableView.dequeueReusableCell(TxFooterCell.self, indexPath: indexPath)!
            cell.configure(viewModel: viewModel)
            cell.selectionStyle = .none
            cell.onSelectOpenExplore = { chainID, txHash in
                AppDependencies.router.openTxHash(txHash: txHash, chainID: chainID)
            }
            return cell
        case .date(let date):
            let cell = tableView.dequeueReusableCell(TxDateCell.self, indexPath: indexPath)!
            cell.configure(date: date)
            cell.selectionStyle = .none
            return cell
        case .nft(let viewModel):
            let cell = tableView.dequeueReusableCell(TxNFTCell.self, indexPath: indexPath)!
            cell.configure(viewModel: viewModel)
            cell.selectionStyle = .none
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if !viewModel.isLoading && indexPath.item == viewModel.rows.count - 15 && viewModel.canLoadMore {
            self.viewModel.load(shouldReset: false)
        }
    }
    
}


extension TxHistoryViewController: SkeletonTableViewDataSource {
    
    func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
        return TxSkeletonCell.className
    }
    
    func collectionSkeletonView(_ skeletonView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
}

extension TxHistoryViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
        tokenSelectPopup?.updateQuery(text: text, chain: viewModel.currentChain)
        searchContainerView.isHidden = text.isEmpty
        return true
    }
    
}
