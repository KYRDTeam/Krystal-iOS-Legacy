//
//  StakingPortfolioViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 11/10/2022.
//

import UIKit
import BaseModule
import StackViewController
import SkeletonView
import AppState
import Utilities
import Services
import DesignSystem
import TransactionModule
import SwipeCellKit

class SkeletonBlankSectionHeader: UITableViewHeaderFooterView {
  override init(reuseIdentifier: String?) {
    super.init(reuseIdentifier: reuseIdentifier)
    self.isSkeletonable = true
    self.backgroundColor = AppTheme.current.sectionBackgroundColor
    
  }
  required init(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

class StakingPortfolioViewController: InAppBrowsingViewController {
  @IBOutlet weak var portfolioTableView: UITableView!
  @IBOutlet weak var emptyViewContainer: UIView!
  @IBOutlet weak var emptyIcon: UIImageView!
  @IBOutlet weak var emptyLabel: UILabel!
  
  @IBOutlet weak var searchFieldActionButton: UIButton!
  @IBOutlet weak var searchViewRightConstraint: NSLayoutConstraint!
  @IBOutlet weak var cancelButton: UIButton!
  @IBOutlet weak var searchTextField: UITextField!
  
  let viewModel: StakingPortfolioViewModel = StakingPortfolioViewModel()
  var timer: Timer?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    registerCell()
    searchTextField.setPlaceholder(text: Strings.searchToken, color: AppTheme.current.secondaryTextColor)
    viewModel.dataSource.observeAndFire(on: self) { _ in
      self.portfolioTableView.reloadData()
      
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
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if viewModel.isEmpty() && viewModel.isLoading.value == false {
      viewModel.requestData()
    }
  }
  
  private func registerCell() {
    portfolioTableView.registerCellNib(StakingPortfolioCell.self)
    portfolioTableView.registerCellNib(SkeletonCell.self)
    portfolioTableView.register(SkeletonBlankSectionHeader.self, forHeaderFooterViewReuseIdentifier: "SectionHeader")
  }
  
  private func updateUIEmptyView() {
    if viewModel.searchText.isEmpty {
      emptyIcon.image = Images.emptyDeposit
      emptyLabel.text = Strings.emptyTokenDeposit
    } else {
      self.emptyIcon.image = Images.emptySearch
      self.emptyLabel.text = Strings.noRecordFound
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
  
  override func reloadWallet() {
    super.reloadWallet()
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
  
  func reloadUI() {
    viewModel.reloadDataSource()
    portfolioTableView.reloadData()
    updateUIEmptyView()
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
    
    func requestClaim(pendingUnstake: PendingUnstake) {
        let viewModel = StakingConfirmClaimPopupViewModel(pendingUnstake: pendingUnstake)
        TxConfirmPopup.show(onViewController: self, withViewModel: viewModel) { [weak self] pendingTx in
            let vc = ClaimTxStatusPopup.instantiateFromNib()
            vc.onOpenPortfolio = { [weak self] in
                self?.viewModel.requestData()
            }
            vc.viewModel = ClaimTxStatusViewModel(pendingTx: pendingTx as! PendingClaimTxInfo)
            self?.present(vc, animated: true)
        }
    }
    
}

extension StakingPortfolioViewController: SkeletonTableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return viewModel.dataSource.value.1.isEmpty ? 1 : 2
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return section == 0 ? viewModel.dataSource.value.0.count : viewModel.dataSource.value.1.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(StakingPortfolioCell.self, indexPath: indexPath)!
    let items = indexPath.section == 0 ? viewModel.dataSource.value.0 : viewModel.dataSource.value.1
    let cm = items[indexPath.row]
    cell.updateCellModel(cm)
    cell.delegate = self
    cell.onTapHint = {
        self.showBottomBannerView(message: cm.timeForUnstakeString())
    }
    cell.chainImageView.isHidden = viewModel.chainID != nil
      cell.claimTapped = { [weak self] in
          guard let self = self else { return }
          guard let pendingUnstake = cm.pendingUnstake else { return }
          self.requestClaim(pendingUnstake: pendingUnstake)
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
    return 10
  }
  
  func numSections(in collectionSkeletonView: UITableView) -> Int {
    return 1
  }
}

extension StakingPortfolioViewController: SkeletonTableViewDelegate {
    
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      let items = indexPath.section == 0 ? viewModel.dataSource.value.0 : viewModel.dataSource.value.1
      let cm = items[indexPath.row]
      guard let pendingUnstake = cm.pendingUnstake else { return }
      requestClaim(pendingUnstake: pendingUnstake)
  }
  
  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 40))
    view.backgroundColor = AppTheme.current.sectionBackgroundColor
    let titleLabel = UILabel(frame: CGRect(x: 35, y: 0, width: 100, height: 40))
    titleLabel.center.y = view.center.y
    titleLabel.text = section == 0 ? "STAKING" : "UNSTAKING"
    titleLabel.font = UIFont(name: "Karla-Regular", size: 14)!//UIFont.Kyber.regular(with: 14)
    titleLabel.textColor = UIColor(named: "textWhiteColor")
    view.addSubview(titleLabel)
    
    return view
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return indexPath.section == 0 ? 162 : 146
  }
  
  func collectionSkeletonView(_ skeletonView: UITableView, identifierForHeaderInSection section: Int) -> ReusableHeaderFooterIdentifier? {
    return "SectionHeader"
  }
}

extension StakingPortfolioViewController: UITextFieldDelegate {
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

extension StakingPortfolioViewController: SwipeTableViewCellDelegate {
  
  func swipeCellImageView(title: String, icon: UIImage, color: UIColor) -> UIImage {
    let containView = UIView(frame: CGRect(x: 0, y: 0, width: 102, height: 84))
    containView.backgroundColor = .clear
    
    let view = UIView(frame: CGRect(x: 0, y: 0, width: 84, height: 84))
    view.layer.cornerRadius = 16
    view.backgroundColor = color.withAlphaComponent(0.1)
    
    let imageView = UIImageView(frame: CGRect(x: 30, y: 20, width: 24, height: 24))
    imageView.image = icon
    view.addSubview(imageView)
    
    let label = UILabel(frame: CGRect(x: 15, y: 52, width: 54, height: 16))
    label.text = title
    label.textColor = color
    label.font = .karlaReguler(ofSize: 14)
    label.textAlignment = .center
    view.addSubview(label)
    
    containView.addSubview(view)
    
    let renderer = UIGraphicsImageRenderer(bounds: containView.bounds)
    return renderer.image { rendererContext in
      containView.layer.render(in: rendererContext.cgContext)
    }
  }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right, indexPath.section == 0 else { return nil }

        let unstakeAction = SwipeAction(style: .default, title: nil) { [weak self] _, _ in
            if let earningBalance = self?.viewModel.portfolio?.0[indexPath.row] {
                let viewModel = UnstakeViewModel(earningBalance: earningBalance)
                let viewController = UnstakeViewController.instantiateFromNib()
                viewController.viewModel = viewModel
                self?.show(viewController, sender: nil)
            }
        }
        let image = swipeCellImageView(title: Strings.unstake, icon: Images.redSubtract, color: AppTheme.current.errorTextColor)
        unstakeAction.image = image
        unstakeAction.backgroundColor = AppTheme.current.sectionBackgroundColor
      
        let stakeAction = SwipeAction(style: .default, title: nil) { [weak self] _, _ in
            let vc = UnstakeViewController.instantiateFromNib()
            self?.show(vc, sender: nil)
        }
        let stakeImage = swipeCellImageView(title: Strings.stake, icon: Images.greenPlus, color: AppTheme.current.primaryColor)
        stakeAction.image = stakeImage
        stakeAction.backgroundColor = AppTheme.current.sectionBackgroundColor
        
        return [unstakeAction, stakeAction]
    }
    
    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        var options = SwipeOptions()
        options.expansionStyle = .selection
        options.minimumButtonWidth = 102
        options.maximumButtonWidth = 102
        
        return options
    }
}
