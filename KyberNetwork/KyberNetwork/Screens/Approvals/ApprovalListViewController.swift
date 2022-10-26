//
//  ApprovalListViewController.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 25/10/2022.
//

import UIKit
import BaseModule
import DesignSystem
import SkeletonView
import TransactionModule
import SwipeCellKit

class ApprovalListViewController: BaseWalletOrientedViewController {
    
    @IBOutlet weak var emptyView: ListEmptyView!
    @IBOutlet weak var riskInfoImageView: UIImageView!
    @IBOutlet weak var searchField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var riskAmountLabel: UILabel!
    private let refreshControl = UIRefreshControl()
    
    var viewModel: ApprovalListViewModel!
    var timer: Timer?
    
    override var supportAllChainOption: Bool {
        return true
    }
    
    override var currentChain: ChainType {
        return viewModel.selectedChain
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        bindViewModel()
        showLoading()
        scheduleShowSwipeHint()
        viewModel.fetchApprovals()
    }
    
    override func onAppSwitchChain() {
        viewModel.selectedChain = KNGeneralProvider.shared.currentChain
        super.onAppSwitchChain()
        showLoading()
        viewModel.fetchApprovals()
    }
    
    override func onAppSelectAllChain() {
        viewModel.selectedChain = .all
        super.onAppSwitchChain()
        showLoading()
        viewModel.fetchApprovals()
    }
    
    override func onAppSwitchAddress() {
        super.onAppSwitchAddress()
        
        showLoading()
        viewModel.fetchApprovals()
    }
    
    deinit {
        timer?.invalidate()
        timer = nil
    }
    
    func scheduleShowSwipeHint() {
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true, block: { [weak self] _ in
            if self?.viewModel.userHasInteractApproval == false {
                if let cell = self?.tableView.cellForRow(at: IndexPath(item: 0, section: 0)) as? ApprovedTokenCell {
                    cell.showSwipe(orientation: .right, animated: true)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        cell.hideSwipe(animated: true)
                    }
                }
            }
        })
    }
    
    func showLoading() {
        let gradient = SkeletonGradient(baseColor: UIColor.Kyber.cellBackground)
        view.showAnimatedGradientSkeleton(usingGradient: gradient)
    }
    
    func hideLoading() {
        view.hideSkeleton()
    }
    
    func bindViewModel() {
        viewModel.onFetchApprovals = { [weak self] in
            DispatchQueue.main.async {
                self?.hideLoading()
                self?.riskAmountLabel.text = self?.viewModel.totalAllowanceString
                self?.emptyView.isHidden = self?.viewModel.filteredApprovals.isEmpty == false
                self?.emptyView.setup(icon: Images.noApprovals, message: Strings.approvalsNoRisk)
                self?.tableView.reloadData()
            }
        }
        
        viewModel.onFilterApprovalsUpdated = { [weak self] in
            DispatchQueue.main.async {
                self?.emptyView.isHidden = self?.viewModel.filteredApprovals.isEmpty == false
                self?.emptyView.setup(icon: Images.noRecords, message: Strings.aprovalsNoRecords)
                self?.tableView.reloadData()
            }
        }
    }
    
    func setupViews() {
        view.isUserInteractionDisabledWhenSkeletonIsActive = true
        setupTableView()
        setupSearchField()
        setupTotalAllowanceView()
        setupRefreshControl()
    }
    
    func setupRefreshControl() {
        refreshControl.tintColor = UIColor.white.withAlphaComponent(0.5)
    }
    
    func setupTotalAllowanceView() {
        riskInfoImageView.isUserInteractionEnabled = true
        riskInfoImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showTotalAllowanceInfo)))
    }
    
    @objc func showTotalAllowanceInfo() {
        BottomMessagePopup.show(on: self, title: Strings.totalAllowance, message: Strings.totalAllowanceDescription)
    }
    
    func setupSearchField() {
        searchField.delegate = self
        searchField.setPlaceholder(text: Strings.approvalSearchPlaceholder, color: AppTheme.current.secondaryTextColor)
    }
    
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = .init(frame: .init(x: 0, y: 0, width: 0, height: CGFloat.leastNonzeroMagnitude))
        tableView.registerCellNib(ApprovedTokenCell.self)
        tableView.registerCellNib(OverviewSkeletonCell.self)
        if #available(iOS 10.0, *) {
            tableView.refreshControl = refreshControl
        } else {
            tableView.addSubview(refreshControl)
        }
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
    }
    
    @objc func refreshData() {
        refreshControl.endRefreshing()
        showLoading()
        viewModel.fetchApprovals()
    }
    
    @IBAction func backWasTapped(_ sender: Any) {
        viewModel.onTapBack()
    }
    
    @IBAction func historyTapped(_ sender: Any) {
        viewModel.onTapHistory()
    }
    
    func disableHint() {
        viewModel.userHasInteractApproval = true
        timer?.invalidate()
        timer = nil
    }
    
}

extension ApprovalListViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
        viewModel.searchText = text
        return true
    }
    
}

extension ApprovalListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.filteredApprovals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(ApprovedTokenCell.self, indexPath: indexPath)!
        cell.selectionStyle = .none
        cell.delegate = self
        if let approval = viewModel.filteredApprovals[safe: indexPath.row] {
            cell.configure(viewModel: approval)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 84
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        timer?.invalidate()
        timer = nil
    }
    
}

extension ApprovalListViewController: SwipeTableViewCellDelegate {
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right else { return nil }
        
        let delete = SwipeAction(style: .default, title: nil) { [weak self] _, _ in
            // TODO: revoke
            self?.disableHint()
        }
        delete.image = Images.revoke
        delete.title = Strings.revoke
        delete.textColor = AppTheme.current.primaryColor
        delete.font = .karlaReguler(ofSize: 14)
        delete.backgroundColor = AppTheme.current.primaryColor.withAlphaComponent(0.1)
        
        return [delete]
    }
    
    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        var options = SwipeOptions()
        options.expansionStyle = .selection
        options.minimumButtonWidth = 84
        options.maximumButtonWidth = 84
        
        return options
    }
}

extension ApprovalListViewController: SkeletonTableViewDataSource {
    
    func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
        return OverviewSkeletonCell.className
    }
    
    func collectionSkeletonView(_ skeletonView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
}
