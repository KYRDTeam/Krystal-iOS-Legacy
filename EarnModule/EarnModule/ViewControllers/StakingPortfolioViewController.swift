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
import FittedSheets
import Dependencies

protocol StakingPortfolioViewControllerDelegate: class {
    func didSelectPlatform(token: Token, platform: EarnPlatform, chainId: Int)
}

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
    @IBOutlet weak var filterButton: UIButton!
    @IBOutlet weak var searchFieldActionButton: UIButton!
    @IBOutlet weak var searchTextField: UITextField!
    
    weak var delegate: StakingPortfolioViewControllerDelegate?
    
    let viewModel: StakingPortfolioViewModel = StakingPortfolioViewModel()
    var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerCell()
        portfolioTableView.backgroundColor = AppTheme.current.sectionBackgroundColor
        searchTextField.setPlaceholder(text: Strings.searchToken, color: AppTheme.current.secondaryTextColor)
        viewModel.displayDataSource.observeAndFire(on: self) { _ in
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
        Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { [weak self] _ in
            self?.viewModel.requestData(shouldShowLoading: false)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.shouldAnimateChart = true
        if viewModel.isEmpty() && viewModel.isLoading.value == false {
            viewModel.requestData()
        }
        portfolioTableView.reloadData()
		AppDependencies.tracker.track("mob_earn_portfolio", properties: ["screenid": "earn_v2"])
    }
    
    private func registerCell() {
        portfolioTableView.registerCellNib(StakingPortfolioCell.self)
        portfolioTableView.registerCellNib(SkeletonCell.self)
        portfolioTableView.registerCellNib(PortfolioPieChartCell.self)
        portfolioTableView.register(SkeletonBlankSectionHeader.self, forHeaderFooterViewReuseIdentifier: "SectionHeader")
    }
    
    private func updateUIEmptyView() {
        guard isViewLoaded else { return }
        if viewModel.isSupportEarnv2 {
            if viewModel.searchText.isEmpty {
                emptyIcon.image = Images.emptyDeposit
                emptyLabel.text = Strings.emptyTokenDeposit
            } else {
                self.emptyIcon.image = Images.emptySearch
                self.emptyLabel.text = Strings.noRecordFound
            }
        } else {
            emptyIcon.image = Images.emptyDeposit
            emptyLabel.text = Strings.earnIsCurrentlyNotSupportedOnThisChainYet
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
            self.searchFieldActionButton.setImage(UIImage(named: "close-search-icon"), for: .normal)
            self.view.layoutIfNeeded()
        }
    }
    
    func updateUIEndSearchingMode() {
        self.view.layoutIfNeeded()
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0, options: .curveEaseInOut) {
            self.searchFieldActionButton.setImage(UIImage(named: "search_blue_icon"), for: .normal)
            self.view.endEditing(true)
            self.view.layoutIfNeeded()
        }
    }
    
    @IBAction func onSearchButtonTapped(_ sender: Any) {
        self.updateUIStartSearchingMode()
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
        AppDependencies.tracker.track("mob_portfolio_claim", properties: ["screenid": "earn_v2"])
        let viewModel = StakingConfirmClaimPopupViewModel(pendingUnstake: pendingUnstake)
        TxConfirmPopup.show(onViewController: self, withViewModel: viewModel) { [weak self] pendingTx in
            let vc = ClaimTxStatusPopup.instantiateFromNib()
            vc.onOpenPortfolio = { [weak self] in
                self?.viewModel.requestData()
            }
            vc.viewModel = ClaimTxStatusViewModel(pendingTx: pendingTx as! PendingClaimTxInfo)
            let sheet = SheetViewController(controller: vc, sizes: [.intrinsic], options: .init(pullBarHeight: 0))
            self?.present(sheet, animated: true)
            AppDependencies.tracker.track("mob_portfolio_claim_confirm", properties: ["screenid": "earn_v2_claim_pop_up"])
        }
    }

    func updateSupportedEarnv2(_ value: Bool) {
        guard viewModel.isSupportEarnv2 != value else {
            return
        }
        viewModel.isSupportEarnv2 = value
        updateUIEmptyView()
    }
    
    func animateChartCell(isExpand: Bool) {
        if !isExpand {
            self.view.layoutIfNeeded()
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0, options: .curveEaseInOut) {
                if let cell = self.portfolioTableView.cellForRow(at: IndexPath(row: 0, section: 0)) {
                    var rect = cell.frame
                    rect.size.height = 0
                    cell.frame = rect
                }
                self.view.layoutIfNeeded()
            }
        } else {
            self.view.layoutIfNeeded()
            if let cell = self.portfolioTableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? PortfolioPieChartCell {
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0, options: .curveEaseInOut) {
                    var rect = cell.frame
                    rect.size.height = 390
                    cell.frame = rect
                    self.view.layoutIfNeeded()
                } completion: { complete in
                    cell.updateUI(animate: true)
                    self.viewModel.shouldAnimateChart = false
                }
            }
        }
    }
}

extension StakingPortfolioViewController: SkeletonTableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSection()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRows(section: section)
    }
    
    func chartCell(_ tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(PortfolioPieChartCell.self, indexPath: indexPath)!
        if let portfolio = viewModel.portfolio {
            cell.viewModel = PortfolioPieChartCellViewModel(earningBalances: portfolio.0, chainID: viewModel.chainID)
            cell.updateUI(animate: viewModel.shouldAnimateChart)
            viewModel.shouldAnimateChart = false
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            return chartCell(tableView, indexPath: indexPath)
        }
        let cell = tableView.dequeueReusableCell(StakingPortfolioCell.self, indexPath: indexPath)!
        let items = indexPath.section == 1 ? viewModel.displayDataSource.value.0 : viewModel.displayDataSource.value.1
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
        cell.onTapRewardApy = { balance in
            let messge = String(format: Strings.rewardApyInfoText, NumberFormatUtils.percent(value: balance.apy), NumberFormatUtils.percent(value: balance.rewardApy))
            self.showTopBannerView(message: messge)
		}
		
        cell.onTapWarningIcon = { type in
            switch type {
            case .disable:
                self.showErrorTopBannerMessage(message: Strings.stakeDisableMessage)
            case .warning:
                self.showErrorTopBannerMessage(message: Strings.stakeWarningMessage)
            case .none:
                break
            }
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

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
      return CGFloat(46.0)
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat(1.0)
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return viewModel.viewForFooter(tableView)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = viewModel.viewForHeader(tableView, section: section)
        view.onTapped = { isExpand in
            self.viewModel.shouldAnimateChart = isExpand
            self.viewModel.updateShowHideSection(section: section, isExpand: isExpand)
            self.portfolioTableView.beginUpdates()
            if section == 0 {
                self.animateChartCell(isExpand: isExpand)
            }
            self.portfolioTableView.endUpdates()
        }
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return viewModel.heightForRow(section: indexPath.section)
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
        label.font = .karlaReguler(ofSize: 12)
        label.textAlignment = .center
        view.addSubview(label)
        
        containView.addSubview(view)
        
        let renderer = UIGraphicsImageRenderer(bounds: containView.bounds)
        return renderer.image { rendererContext in
            containView.layer.render(in: rendererContext.cgContext)
        }
    }
    
    func plusTitleFor(earningType: EarningType) -> String {
        switch earningType {
        case .staking:
            return Strings.stake
        case .lending:
            return Strings.supply
        }
    }
    
    func minusTitleFor(earningType: EarningType) -> String {
        switch earningType {
        case .staking:
            return Strings.unstake
        case .lending:
            return Strings.withdraw
        }
    }
    
    func openUnstake(earningBalance: EarningBalance) {
        let earningType = EarningType(value: earningBalance.platform.type)
        if earningBalance.toUnderlyingToken.address.lowercased() == Constants.ethAddress.lowercased() && earningType == .staking {
            self.showUnstakeETHWarning()
            return
        }
        let viewModel = UnstakeViewModel(earningBalance: earningBalance)
        let viewController = UnstakeViewController.instantiateFromNib()
        viewController.viewModel = viewModel
        self.show(viewController, sender: nil)
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right, indexPath.section == 1 else { return nil }
        let earningBalances = self.viewModel.displayDataSource.value.0.map { $0.earnBalance }
        guard let earningBalance = earningBalances[indexPath.row] else { return nil }
        let earningType = EarningType(value: earningBalance.platform.type)
        
        let unstakeAction = SwipeAction(style: .default, title: nil) { [weak self] _, _ in
            guard let self = self else { return }
            if earningBalance.chainID == AppState.shared.currentChain.getChainId() {
              self.openUnstake(earningBalance: earningBalance)
            } else {
              let newChain = ChainType.make(chainID: earningBalance.chainID) ?? AppState.shared.currentChain
              SwitchSpecificChainPopup.show(onViewController: self, destChain: newChain) {
                  self.openUnstake(earningBalance: earningBalance)
              }
            }
        }
        let image = swipeCellImageView(title: minusTitleFor(earningType: earningType), icon: Images.redSubtract, color: AppTheme.current.errorTextColor)
        unstakeAction.image = image
        unstakeAction.backgroundColor = AppTheme.current.sectionBackgroundColor
        
        let stakeAction = SwipeAction(style: .default, title: nil) { [weak self] _, _ in
            guard let chain = ChainType.make(chainID: earningBalance.chainID) else { return }
            if chain != AppState.shared.currentChain {
                AppState.shared.updateChain(chain: chain)
            }
            let token = Token(name: earningBalance.toUnderlyingToken.symbol,
                              symbol: earningBalance.toUnderlyingToken.symbol,
                              address: earningBalance.toUnderlyingToken.address,
                              decimals: earningBalance.toUnderlyingToken.decimals,
                              logo: earningBalance.toUnderlyingToken.logo)
            let earnPlatform = EarnPlatform(platform: earningBalance.platform, apy: earningBalance.apy, tvl: 0)
            self?.delegate?.didSelectPlatform(token: token, platform: earnPlatform, chainId: earningBalance.chainID)
        }
        let stakeImage = swipeCellImageView(title: plusTitleFor(earningType: earningType), icon: Images.greenPlus, color: AppTheme.current.primaryColor)
        stakeAction.image = stakeImage
        stakeAction.backgroundColor = AppTheme.current.sectionBackgroundColor
        
        let cellModel = viewModel.displayDataSource.value.0[indexPath.row]
        
        if cellModel.warningType == .none {
            return [unstakeAction, stakeAction]
        } else {
            return [stakeAction]
        }
        
        
    }
    
    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        var options = SwipeOptions()
        options.expansionStyle = .selection
        options.minimumButtonWidth = 102
        options.maximumButtonWidth = 102
        options.backgroundColor = AppTheme.current.sectionBackgroundColor
        return options
    }
    
    private func showUnstakeETHWarning() {
        let alertController = KNPrettyAlertController(
            title: Strings.warning,
            isWarning: true,
            message: Strings.unstakeEthWarningPopupMessage,
            secondButtonTitle: nil,
            firstButtonTitle: Strings.ok,
            secondButtonAction: {
            },
            firstButtonAction: {
            }
        )
        
        alertController.popupHeight = 320
        present(alertController, animated: true, completion: nil)
    }
}

extension StakingPortfolioViewController: PlatformFilterViewControllerDelegate {
    func didSelectPlatform(viewController: PlatformFilterViewController, selected: Set<EarnPlatform>, types: [EarningType]) {
        viewModel.selectedPlatforms = selected
        viewModel.selectedTypes = types
        reloadUI()
    }
}
