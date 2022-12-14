//
//  EarnListViewController.swift
//  KyberNetwork
//
//  Created by Com1 on 12/10/2022.
//

import UIKit
import SkeletonView
import BaseModule
import Dependencies
import AppState
import Services
import DesignSystem
import FittedSheets
import Utilities

protocol EarnListViewControllerDelegate: class {
    func didSelectPlatform(platform: EarnPlatform, pool: EarnPoolModel)
}

class EarnListViewController: InAppBrowsingViewController {
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchFieldActionButton: UIButton!
    @IBOutlet weak var searchViewRightConstraint: NSLayoutConstraint!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var emptyView: UIView!
    weak var delegate: EarnListViewControllerDelegate?
    var isNeedReloadFilter = true
    
    @IBOutlet weak var platformFilterButton: UIButton!
    @IBOutlet weak var emptyIcon: UIImageView!
    @IBOutlet weak var emptyLabel: UILabel!
    var dataSource: [EarnPoolViewCellViewModel] = []
    var displayDataSource: [EarnPoolViewCellViewModel] = []
    var timer: Timer?
    var currentSelectedChain: ChainType = AppState.shared.isSelectedAllChain ? .all : AppState.shared.currentChain
    var selectedPlatforms: Set<EarnPlatform>!
    var isSupportEarnv2: Observable<Bool> = .init(true)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        selectedPlatforms = Set(getAllPlatform())
        fetchData(chainId: currentSelectedChain == .all ? nil : currentSelectedChain.getChainId())
        Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { [weak self] _ in
            self?.fetchData(chainId: self?.currentSelectedChain == .all ? nil : self?.currentSelectedChain.getChainId(), isAutoReload: true)
        }
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func onAppSwitchChain() {
        isNeedReloadFilter = true
        currentSelectedChain = AppState.shared.currentChain
        fetchData(chainId: currentSelectedChain == .all ? nil : currentSelectedChain.getChainId())
    }
    
    override func onAppSelectAllChain() {
        isNeedReloadFilter = true
        currentSelectedChain = .all
        fetchData()
    }
    
    func setupUI() {
        self.searchTextField.setPlaceholder(text: Strings.searchToken, color: AppTheme.current.secondaryTextColor)
        self.tableView.registerCellNib(EarnPoolViewCell.self)
    }
    
    private func isSelectedAllPlatforms() -> Bool {
        return selectedPlatforms.isEmpty || selectedPlatforms.count == getAllPlatform().count
    }
    
    func reloadUI() {
        displayDataSource = dataSource
        if let text = self.searchTextField.text, !text.isEmpty {
            self.displayDataSource = self.dataSource.filter({ viewModel in
                let containSymbol = viewModel.earnPoolModel.token.symbol.lowercased().contains(text.lowercased())
                let containName = viewModel.earnPoolModel.token.name.lowercased().contains(text.lowercased())
                return containSymbol || containName
            })
            if self.displayDataSource.isEmpty {
                self.emptyIcon.image = UIImage(named: "empty-search-token")
                self.emptyLabel.text = Strings.noRecordFound
            }
        }
        
        if !isSelectedAllPlatforms() {
            self.displayDataSource = self.displayDataSource.filter { element in
                let modelPfSet: Set<EarnPlatform> = Set(element.earnPoolModel.platforms)
                return modelPfSet.intersection(self.selectedPlatforms).count >= 1
            }
            
            displayDataSource.forEach { item in
                item.filteredPlatform = self.selectedPlatforms
            }
            if self.displayDataSource.isEmpty {
                self.emptyIcon.image = UIImage(named: "empty-search-token")
                self.emptyLabel.text = Strings.noRecordFound
            }
        } else {
            displayDataSource.forEach { item in
                item.filteredPlatform = nil
            }
        }
        
        self.emptyView.isHidden = !self.displayDataSource.isEmpty
        self.isSupportEarnv2.value = !self.displayDataSource.isEmpty
        self.tableView.reloadData()
        updateUIPlatformFilterButton()
    }
    
    func fetchData(chainId: Int? = nil, isAutoReload: Bool = false) {
        if !isAutoReload {
            self.displayDataSource.forEach { viewModel in
                viewModel.isExpanse = false
            }
            reloadUI()
        }
        let service = EarnServices()
        if !isAutoReload {
            showLoading()
        }
        
        var chainIdString: String?
        if let chainId = chainId {
            chainIdString = "\(chainId)"
        }
        service.getEarnListData(chainId: chainIdString) { listData in
            var data: [EarnPoolViewCellViewModel] = []
            listData.forEach { earnPoolModel in
                data.append(EarnPoolViewCellViewModel(earnPool: earnPoolModel))
            }
            if data.isEmpty {
                self.emptyIcon.image = UIImage(named: "empty_earn_icon")
                self.emptyLabel.text = Strings.earnIsCurrentlyNotSupportedOnThisChainYet
            }
            
            self.dataSource = data
            var displayData: [EarnPoolViewCellViewModel] = []
            data.forEach { cellVM in
                if let oldVM = self.displayDataSource.first { object in
                    return object.earnPoolModel.chainID == cellVM.earnPoolModel.chainID && object.earnPoolModel.token.address.lowercased() == cellVM.earnPoolModel.token.address.lowercased()
                } {
                    cellVM.isExpanse = oldVM.isExpanse
                }
                displayData.append(cellVM)
            }
            
            self.displayDataSource = displayData
            if let text = self.searchTextField.text, !text.isEmpty {
                self.filterDataSource(text: text)
            }
            if !isAutoReload {
                self.hideLoading()
            }
            if self.isNeedReloadFilter {
                self.isNeedReloadFilter = false
                self.selectedPlatforms = self.getAllPlatform()
            }
            self.reloadUI()
        }
    }
    
    private func getAllPlatform() -> Set<EarnPlatform> {
        var platformSet = Set<EarnPlatform>()
        
        dataSource.forEach { item in
            item.earnPoolModel.platforms.forEach { element in
                platformSet.insert(element)
            }
        }
        return platformSet
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
            self.fetchData(chainId: currentSelectedChain == .all ? nil : currentSelectedChain.getChainId())
        } else {
            self.updateUIStartSearchingMode()
        }
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        self.updateUIEndSearchingMode()
    }
    
    @IBAction func platformFilterButtonTapped(_ sender: UIButton) {
        let allPlatforms = getAllPlatform()
        let viewModel = PlatformFilterViewModel(dataSource: allPlatforms, selected: selectedPlatforms)
        let viewController = PlatformFilterViewController.instantiateFromNib()
        viewController.viewModel = viewModel
        viewController.delegate = self
        let sheetOptions = SheetOptions(pullBarHeight: 0)
        let sheet = SheetViewController(controller: viewController, sizes: [.intrinsic], options: sheetOptions)
        present(sheet, animated: true)
    }
    
    private func updateUIPlatformFilterButton() {
        if isSelectedAllPlatforms() {
            platformFilterButton.setTitle(Strings.allPlatforms, for: .normal)
            return
        }
        let name = selectedPlatforms.map { $0.name.capitalized }.joined(separator: ", ")
        platformFilterButton.setTitle(name, for: .normal)
    }
}

extension EarnListViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayDataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(EarnPoolViewCell.self, indexPath: indexPath)!
        let viewModel = displayDataSource[indexPath.row]
        cell.updateUI(viewModel: viewModel, shouldShowChainIcon: currentSelectedChain == .all)
        cell.delegate = self
        return cell
    }
}

extension EarnListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cellViewModel = displayDataSource[indexPath.row]
        cellViewModel.isExpanse = !cellViewModel.isExpanse
        self.tableView.beginUpdates()
        if let cell = self.tableView.cellForRow(at: indexPath) as? EarnPoolViewCell {
            animateCellHeight(cell: cell, viewModel: cellViewModel)
        }
        self.tableView.endUpdates()
        AppDependencies.tracker.track("mob_earn_select_token", properties: ["screenid": "earn_v2"])
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let cellViewModel = displayDataSource[indexPath.row]
        return cellViewModel.height()
    }
    
    func animateCellHeight(cell: EarnPoolViewCell, viewModel: EarnPoolViewCellViewModel) {
        self.view.layoutIfNeeded()
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0, options: .curveEaseInOut) {
            var rect = cell.frame
            rect.size.height = viewModel.height()
            cell.frame = rect
            cell.updateUIExpanse(viewModel: viewModel)
            self.view.layoutIfNeeded()
        }
    }
}

extension EarnListViewController: SkeletonTableViewDelegate, SkeletonTableViewDataSource {
    
    func showLoading() {
        let gradient = SkeletonGradient(baseColor: AppTheme.current.sectionBackgroundColor)
        view.showAnimatedGradientSkeleton(usingGradient: gradient)
    }
    
    func hideLoading() {
        view.hideSkeleton()
    }
    
    func collectionSkeletonView(_ skeletonView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func collectionSkeletonView(_ skeletonView: UITableView, skeletonCellForRowAt indexPath: IndexPath) -> UITableViewCell? {
        let cell = skeletonView.dequeueReusableCell(EarnPoolViewCell.self, indexPath: indexPath)!
        return cell
    }
    
    func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
        return EarnPoolViewCell.className
    }
}

extension EarnListViewController: UITextFieldDelegate {
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
    
    func filterDataSource(text: String) {
        self.displayDataSource = self.dataSource.filter({ viewModel in
            let containSymbol = viewModel.earnPoolModel.token.symbol.lowercased().contains(text.lowercased())
            let containName = viewModel.earnPoolModel.token.name.lowercased().contains(text.lowercased())
            return containSymbol || containName
        })
    }
    
    @objc func doSearch() {
        if let text = self.searchTextField.text, !text.isEmpty {
            filterDataSource(text: text)
            if self.displayDataSource.isEmpty {
                self.emptyIcon.image = UIImage(named: "empty-search-token")
                self.emptyLabel.text = Strings.noRecordFound
            }
            self.reloadUI()
        } else {
            self.fetchData(chainId: currentSelectedChain == .all ? nil : currentSelectedChain.getChainId())
        }
    }
}

extension EarnListViewController: EarnPoolViewCellDelegate {
    func didSelectRewardApy(platform: EarnPlatform, pool: EarnPoolModel) {
        let messge = String(format: Strings.rewardApyInfoText, NumberFormatUtils.percent(value: pool.apy), NumberFormatUtils.percent(value: platform.rewardApy))
        showTopBannerView(message: messge)
    }
    
    func didSelectPlatform(platform: EarnPlatform, pool: EarnPoolModel) {
        delegate?.didSelectPlatform(platform: platform, pool: pool)
    }
}

extension EarnListViewController: PlatformFilterViewControllerDelegate {
    func didSelectPlatform(viewController: PlatformFilterViewController, selected: Set<EarnPlatform>) {
        selectedPlatforms = selected
        viewController.dismiss(animated: true) {
            self.updateUIPlatformFilterButton()
            self.reloadUI()
        }
    }
}
