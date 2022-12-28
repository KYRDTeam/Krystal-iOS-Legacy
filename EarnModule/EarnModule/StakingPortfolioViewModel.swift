//
//  StakingPortfolioViewModel.swift
//  EarnModule
//
//  Created by Ta Minh Quan on 11/29/2022.
//

import UIKit
import Services
import AppState
import DesignSystem

class StakingPortfolioViewModel {
    var portfolio: ([EarningBalance], [PendingUnstake])?
    let apiService = EarnServices()
    var searchText = ""
    var chainID: Int?
    var dataSource: Observable<([StakingPortfolioCellModel], [StakingPortfolioCellModel])> = .init(([], []))
    var displayDataSource: Observable<([StakingPortfolioCellModel], [StakingPortfolioCellModel])> = .init(([], []))
    var error: Observable<Error?> = .init(nil)
    var isLoading: Observable<Bool> = .init(true)
    var selectedPlatforms: Set<EarnPlatform> = Set()
    var selectedTypes: [EarningType] = [.staking, .lending]
    var isSupportEarnv2: Bool = true
    var showChart: Bool = true
    var showStaking: Bool = false
    var showPending: Bool = false
    var shouldAnimateChart: Bool = true
    var isEditing: Bool = false
    
    func cleanAllData() {
        dataSource.value.0.removeAll()
        dataSource.value.1.removeAll()
        displayDataSource.value.0.removeAll()
        displayDataSource.value.1.removeAll()
    }
    
    func isEmpty() -> Bool {
        return dataSource.value.0.isEmpty && dataSource.value.1.isEmpty
    }
    
    func reloadDataSource() {
        cleanAllData()
        var output: [StakingPortfolioCellModel] = []
        var pending: [StakingPortfolioCellModel] = []
        
        var pendingUnstakeData = filterPendingUnstake()
        var earningBalanceData = filterEarningBalance()

        pendingUnstakeData.forEach({ item in
            pending.append(StakingPortfolioCellModel(pendingUnstake: item))
        })
        
        earningBalanceData.forEach { item in
            output.append(StakingPortfolioCellModel(earnBalance: item))
        }
        
        displayDataSource.value = (output, pending)
        dataSource.value = (output, pending)
    }
    
    func filterEarningBalance() -> [EarningBalance] {
        guard let data = portfolio else {
            return []
        }
        var earningBalanceData = data.0
        
        if !searchText.isEmpty {
            earningBalanceData = earningBalanceData.filter({ item in
                return item.stakingToken.symbol.lowercased().contains(searchText) || item.toUnderlyingToken.symbol.lowercased().contains(searchText) || item.stakingToken.name.lowercased().contains(searchText) || item.toUnderlyingToken.name.lowercased().contains(searchText)
            })
        }
        if let unwrap = chainID {
            earningBalanceData = earningBalanceData.filter({ item in
                return item.chainID == unwrap
            })
        }
        if !isSelectedAllPlatform {
            earningBalanceData = earningBalanceData.filter({ item in
                return self.selectedPlatforms.contains(item.platform.toEarnPlatform())
            })
        }
        earningBalanceData = earningBalanceData.filter({ item in
            let earningType = EarningType(value: item.platform.type)
            return self.selectedTypes.contains(earningType)
        })

        return earningBalanceData
    }
    
    func filterPendingUnstake() -> [PendingUnstake] {
        guard let data = portfolio else {
            return []
        }
        var pendingUnstakeData = data.1
        if !searchText.isEmpty {
            pendingUnstakeData = pendingUnstakeData.filter({ item in
                return item.symbol.lowercased().contains(searchText)
            })
        }
        if let unwrap = chainID {
            pendingUnstakeData = pendingUnstakeData.filter({ item in
                return item.chainID == unwrap
            })
        }
        if !isSelectedAllPlatform {
            pendingUnstakeData = pendingUnstakeData.filter({ item in
                return self.selectedPlatforms.contains(item.platform.toEarnPlatform())
            })
        }
        pendingUnstakeData = pendingUnstakeData.filter({ item in
            let earningType = EarningType(value: item.platform.type)
            return self.selectedTypes.contains(earningType)
        })
        return pendingUnstakeData
    }
    
    func requestData(shouldShowLoading: Bool = true) {
        if shouldShowLoading {
            isLoading.value = true
        }
        
        apiService.getStakingPortfolio(address: AppState.shared.currentAddress.addressString, chainId: nil) { result in
            if shouldShowLoading {
                self.isLoading.value = false
            }
            switch result {
            case .success(let portfolio):
                self.portfolio = portfolio
                if shouldShowLoading {
                    self.resetFilter()
                }
                self.reloadDataSource()
            case .failure(let error):
                self.error.value = error
            }
        }
    }
    
    func resetFilter() {
        self.selectedPlatforms = []
        self.selectedTypes = [.staking, .lending]
    }
    
    func getAllPlatform() -> Set<EarnPlatform> {
        guard let portfolio = portfolio else {
            return Set()
        }
        
        var platformSet = Set<EarnPlatform>()
        
        portfolio.0.map { $0.platform.toEarnPlatform() }.forEach { element in
            platformSet.insert(element)
        }
        
        portfolio.1.map { $0.platform.toEarnPlatform() }.forEach { element in
            platformSet.insert(element)
        }
        
        return platformSet
    }
    
    var isSelectedAllPlatform: Bool {
        return selectedPlatforms.isEmpty || selectedPlatforms.count == getAllPlatform().count
    }
    
    var isSelectedAllType: Bool {
        return selectedTypes.contains(.staking) && selectedTypes.contains(.lending)
    }
    
    var platformFilterButtonTitle: String {
        if isSelectedAllPlatform {
            return Strings.allPlatforms
        }
        let name = selectedPlatforms.map { $0.name.capitalized }.joined(separator: ", ")
        return name
    }
    
    func viewForHeader(_ tableView: UITableView, section: Int) -> PortfolioHeaderView {
        let view = PortfolioHeaderView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 46))
        view.shouldShowIcon = section == 0
        if section == 0 {
            view.titleLable.text = Strings.chart
            view.isExpand = showChart
        } else if section == 1 {
            view.titleLable.text = Strings.mySupply
            view.isExpand = showStaking
        } else {
            view.titleLable.text = Strings.unstakingInProgress
            view.isExpand = showPending
        }
        
        return view
    }
    
    func viewForFooter(_ tableView: UITableView) -> UIView {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 1))
        let seperatoView = UIView(frame: CGRect(x: 22, y: 0, width: tableView.frame.size.width - 44, height: 1))
        seperatoView.backgroundColor = AppTheme.current.separatorColor
        view.addSubview(seperatoView)
        return view
    }
    
    func numberOfRows(section: Int) -> Int {
        if section == 0 {
            return 1
        } else if section == 1 {
            return displayDataSource.value.0.count
        } else {
            return displayDataSource.value.1.count
        }
    }
    
    func numberOfSection() -> Int {
        return dataSource.value.1.isEmpty ? 2 : 3
    }
    
    func updateShowHideSection(section: Int, isExpand: Bool) {
        if section == 0 {
            showChart = isExpand
        } else if section == 1 {
            showStaking = isExpand
        } else if section == 2 {
            showPending = isExpand
        }
    }
    
    func heightForRow(section: Int) -> CGFloat {
        if section == 0 {
            if showChart {
                let viewModel = PortfolioPieChartCellViewModel(earningBalances: portfolio?.0 ?? [], chainID: chainID)
                return viewModel.cellHeight
            }
            return 0
        } else if section == 1 {
            return showStaking ? 160 : 0
        } else if section == 2 {
            return showPending ? 170 : 0
        } else {
            return 0
        }
    }
}
