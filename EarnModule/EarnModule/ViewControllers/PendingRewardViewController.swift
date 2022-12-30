//
//  PendingRewardViewController.swift
//  EarnModule
//
//  Created by Ta Minh Quan on 09/12/2022.
//

import UIKit

import AppState
import SkeletonView
import DesignSystem
import TransactionModule
import FittedSheets
import Services
import BaseModule

class PendingRewardViewController: InAppBrowsingViewController {
    
    @IBOutlet weak var searchFieldActionButton: UIButton!
    @IBOutlet weak var searchViewRightConstraint: NSLayoutConstraint!
    @IBOutlet weak var searchTextField: UITextField!
    
    @IBOutlet weak var rewardTableView: UITableView!
    
    @IBOutlet weak var emptyViewContainer: UIView!
    @IBOutlet weak var emptyIcon: UIImageView!
    @IBOutlet weak var emptyLabel: UILabel!
    
    let viewModel = PendingRewardViewModel()
    var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        registerCell()
        searchTextField.setPlaceholder(text: Strings.searchToken, color: AppTheme.current.secondaryTextColor)
        viewModel.dataSource.observeAndFire(on: self) { _ in
            self.rewardTableView.reloadData()
            self.updateUIEmptyView()
            
        }
        viewModel.isLoading.observeAndFire(on: self) { status in
            if status {
                self.showLoadingSkeleton()
            } else {
                self.hideLoadingSkeleton()
                self.updateUIEmptyView()
            }
        }
        viewModel.isClaiming.observeAndFire(on: self) { value in
            if value {
                self.displayLoading()
            } else {
                self.hideLoading()
            }
        }
        viewModel.errorMsg.observeAndFire(on: self) { value in
            guard !value.isEmpty else { return }
            self.showErrorTopBannerMessage(message: value)
        }
        viewModel.confirmViewModel.observeAndFire(on: self) { value in
            guard let value = value else { return }
            TxConfirmPopup.show(onViewController: self, withViewModel: value) { pendingTx in
                let vc = ClaimTxStatusPopup.instantiateFromNib()
                vc.viewModel = ClaimTxStatusViewModel(pendingTx: pendingTx as! PendingClaimTxInfo)
                vc.viewModel.isRewardClaim = true
                let sheet = SheetViewController(controller: vc, sizes: [.intrinsic], options: .init(pullBarHeight: 0))
                self.present(sheet, animated: true)
            }
        }
        let currentChain = AppState.shared.currentChain
        viewModel.chainID = AppState.shared.isSelectedAllChain ? nil : currentChain.getChainId()
        viewModel.requestData()
        emptyIcon.image = Images.emptyReward
        
        Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { _ in
            self.viewModel.requestData(showLoading: false)
        }
    }
    
    override func reloadWallet() {
        super.reloadWallet()
        viewModel.requestData()
        viewModel.resetFilter()
    }

    func updateUIStartSearchingMode() {
        self.view.layoutIfNeeded()
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0, options: .curveEaseInOut) {
            self.searchFieldActionButton.setImage(UIImage(named: "close-search-icon"), for: .normal)
            self.view.layoutIfNeeded()
        }
        viewModel.isEditing = true
    }
    
    func updateUIEndSearchingMode() {
        self.view.layoutIfNeeded()
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0, options: .curveEaseInOut) {
            self.searchFieldActionButton.setImage(UIImage(named: "search_blue_icon"), for: .normal)
            self.view.endEditing(true)
            self.view.layoutIfNeeded()
        }
        viewModel.isEditing = false
    }
    
    func reloadUI() {
        viewModel.reloadDataSource()
        rewardTableView.reloadData()
        updateUIEmptyView()
    }
    
    private func updateUIEmptyView() {
        guard isViewLoaded else { return }
        if viewModel.searchText.isEmpty && viewModel.isSelectedAllPlatform && viewModel.isSelectAllType {
            emptyLabel.text = Strings.noRewardYet
        } else {
            emptyLabel.text = Strings.noRecordFound
        }
        emptyViewContainer.isHidden = !viewModel.isEmpty()
    }
    
    func showLoadingSkeleton() {
        let gradient = SkeletonGradient(baseColor: AppTheme.current.sectionBackgroundColor)
        view.showAnimatedGradientSkeleton(usingGradient: gradient)
    }
    
    func hideLoadingSkeleton() {
        view.hideSkeleton()
    }
    
    @IBAction func onSearchButtonTapped(_ sender: Any) {
        if viewModel.isEditing {
            updateUIEndSearchingMode()
            searchTextField.text = ""
            searchTextField.resignFirstResponder()
            viewModel.searchText = ""
            reloadUI()
        } else {
            updateUIStartSearchingMode()
        }
    }
    
    @IBAction func filterButtonTapped(_ sender: Any) {
        let allPlatforms = viewModel.getAllPlatform()
        let viewModel = PlatformFilterViewModel(dataSource: allPlatforms, selected: viewModel.selectedPlatforms)
        viewModel.shouldShowType = true
        viewModel.selectedType = self.viewModel.selectedTypes
        let viewController = PlatformFilterViewController.instantiateFromNib()
        viewController.viewModel = viewModel
        viewController.delegate = self
        let sheetOptions = SheetOptions(pullBarHeight: 0)
        let sheet = SheetViewController(controller: viewController, sizes: [.intrinsic], options: sheetOptions)
        present(sheet, animated: true)
    }
    
    @objc override func onAppSwitchChain() {
        let currentChain = AppState.shared.currentChain
        viewModel.chainID = currentChain.getChainId()
        viewModel.resetFilter()
        reloadUI()
    }
    
    override func onAppSelectAllChain() {
        viewModel.chainID = nil
        viewModel.resetFilter()
        reloadUI()
    }
    
    private func registerCell() {
        rewardTableView.registerCellNib(PendingRewardCell.self)
        rewardTableView.registerCellNib(SkeletonCell.self)
        rewardTableView.register(SkeletonBlankSectionHeader.self, forHeaderFooterViewReuseIdentifier: "SectionHeader")
    }
}

extension PendingRewardViewController: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        self.updateUIStartSearchingMode()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.updateUIEndSearchingMode()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(doSearch), userInfo: nil, repeats: false)
        return true
    }
    
    @objc func doSearch() {
        if let text = self.searchTextField.text, !text.isEmpty {
            viewModel.searchText = text.lowercased()
        } else {
            viewModel.searchText = ""
        }
        reloadUI()
    }
}

extension PendingRewardViewController: SkeletonTableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.dataSource.value.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(PendingRewardCell.self, indexPath: indexPath)!
        let cellModel = viewModel.dataSource.value[indexPath.row]
        cell.updateCellModel(cellModel)
        cell.chainImageView.isHidden = viewModel.chainID != nil
        cell.onTap = { cm in
            guard AppState.shared.currentChain.getChainId() == cm.rewardItem.chain.id else {
                let chain = ChainType.make(chainID: cm.rewardItem.chain.id) ?? .eth
                SwitchSpecificChainPopup.show(onViewController: self, destChain: chain) {
                    self.viewModel.buildClaimReward(item: cm.rewardItem)
                }
                return
            }
                
            self.viewModel.buildClaimReward(item: cm.rewardItem)
        }
        return cell
    }
    
    // MARK: - Skeleton dataSource
    func collectionSkeletonView(_ skeletonView: UITableView, skeletonCellForRowAt indexPath: IndexPath) -> UITableViewCell? {
        let cell = skeletonView.dequeueReusableCell(SkeletonCell.self, indexPath: indexPath)!
        return cell
    }
    
    func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
        return SkeletonCell.className
    }
    
    func collectionSkeletonView(_ skeletonView: UITableView, prepareCellForSkeleton cell: UITableViewCell, at indexPath: IndexPath) {
    }
    
    func collectionSkeletonView(_ skeletonView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
}

extension PendingRewardViewController: SkeletonTableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 160
    }
    
    func collectionSkeletonView(_ skeletonView: UITableView, identifierForHeaderInSection section: Int) -> ReusableHeaderFooterIdentifier? {
        return "SectionHeader"
    }
    
    func collectionSkeletonView(_ skeletonView: UITableView, identifierForFooterInSection section: Int) -> ReusableHeaderFooterIdentifier? {
        return "SectionHeader"
    }
}

extension PendingRewardViewController: PlatformFilterViewControllerDelegate {
    func didSelectPlatform(viewController: PlatformFilterViewController, selected: Set<EarnPlatform>, types: [EarningType]) {
        viewModel.selectedPlatforms = selected
        viewModel.selectedTypes = types
        reloadUI()
    }
}
