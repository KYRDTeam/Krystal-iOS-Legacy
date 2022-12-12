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

class PendingRewardViewController: InAppBrowsingViewController {
    
    @IBOutlet weak var searchFieldActionButton: UIButton!
    @IBOutlet weak var searchViewRightConstraint: NSLayoutConstraint!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var searchTextField: UITextField!
    
    @IBOutlet weak var rewardTableView: UITableView!
    
    
    let viewModel = PendingRewardViewModel()
    var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        registerCell()
        searchTextField.setPlaceholder(text: Strings.searchToken, color: AppTheme.current.secondaryTextColor)
        viewModel.dataSource.observeAndFire(on: self) { _ in
            self.rewardTableView.reloadData()
            
        }
        viewModel.isLoading.observeAndFire(on: self) { status in
            if status {
                self.showLoadingSkeleton()
            } else {
                self.hideLoadingSkeleton()
                self.updateUIEmptyView()
            }
        }
        let currentChain = AppState.shared.currentChain
        viewModel.chainID = AppState.shared.isSelectedAllChain ? nil : currentChain.getChainId()
        viewModel.requestData()
    }

    func updateUIStartSearchingMode() {
        self.view.layoutIfNeeded()
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0, options: .curveEaseInOut) {
            self.searchViewRightConstraint.constant = 77
            self.cancelButton.isHidden = false
            self.searchFieldActionButton.setImage(UIImage(named: "close-search-icon"), for: .normal)
            self.view.layoutIfNeeded()
        }
    }
    
    func updateUIEndSearchingMode() {
        self.view.layoutIfNeeded()
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0, options: .curveEaseInOut) {
            self.searchViewRightConstraint.constant = 18
            self.cancelButton.isHidden = true
            self.searchFieldActionButton.setImage(UIImage(named: "search_blue_icon"), for: .normal)
            self.view.endEditing(true)
            self.view.layoutIfNeeded()
        }
    }
    
    func reloadUI() {
        viewModel.reloadDataSource()
        rewardTableView.reloadData()
        updateUIEmptyView()
    }
    
    private func updateUIEmptyView() {
        //TODO: placeholder
    }
    
    func showLoadingSkeleton() {
        let gradient = SkeletonGradient(baseColor: AppTheme.current.sectionBackgroundColor)
        view.showAnimatedGradientSkeleton(usingGradient: gradient)
    }
    
    func hideLoadingSkeleton() {
        view.hideSkeleton()
    }
    
    @IBAction func onSearchButtonTapped(_ sender: Any) {
        if !self.cancelButton.isHidden {
            searchTextField.text = ""
            viewModel.searchText = ""
            reloadUI()
        } else {
            self.updateUIStartSearchingMode()
        }
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        self.updateUIEndSearchingMode()
    }
    
    @objc override func onAppSwitchChain() {
        let currentChain = AppState.shared.currentChain
        viewModel.chainID = currentChain.getChainId()
        reloadUI()
    }
    
    override func onAppSelectAllChain() {
        viewModel.chainID = nil
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
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
