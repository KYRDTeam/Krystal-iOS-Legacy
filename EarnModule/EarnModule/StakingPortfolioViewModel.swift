//
//  StakingPortfolioViewModel.swift
//  EarnModule
//
//  Created by Ta Minh Quan on 11/29/2022.
//

import UIKit
import Services
import AppState

class StakingPortfolioViewModel {
    var portfolio: ([EarningBalance], [PendingUnstake])?
    let apiService = EarnServices()
    var searchText = ""
    var chainID: Int?
    
    var dataSource: Observable<([StakingPortfolioCellModel], [StakingPortfolioCellModel])> = .init(([], []))
    var error: Observable<Error?> = .init(nil)
    var isLoading: Observable<Bool> = .init(true)
    var selectedPlatforms: Set<EarnPlatform> = Set()
    
    func cleanAllData() {
        dataSource.value.0.removeAll()
        dataSource.value.1.removeAll()
    }
    
    func isEmpty() -> Bool {
        return dataSource.value.0.isEmpty && dataSource.value.1.isEmpty
    }
    
    func reloadDataSource() {
        cleanAllData()
        guard let data = portfolio else {
            return
        }

        var output: [StakingPortfolioCellModel] = []
        var pending: [StakingPortfolioCellModel] = []
        
        var pendingUnstakeData = data.1
        var earningBalanceData = data.0
        
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
        
        if !searchText.isEmpty {
            earningBalanceData = earningBalanceData.filter({ item in
                return item.stakingToken.symbol.lowercased().contains(searchText) || item.toUnderlyingToken.symbol.lowercased().contains(searchText)
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
            
            pendingUnstakeData = pendingUnstakeData.filter({ item in
                return self.selectedPlatforms.contains(item.platform.toEarnPlatform())
            })
        }
        
        pendingUnstakeData.forEach({ item in
            pending.append(StakingPortfolioCellModel(pendingUnstake: item))
        })
        earningBalanceData.forEach { item in
            output.append(StakingPortfolioCellModel(earnBalance: item))
        }
        dataSource.value = (output, pending)
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
                self.reloadDataSource()
            case .failure(let error):
                self.error.value = error
            }
        }
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
    
    var platformFilterButtonTitle: String {
        if isSelectedAllPlatform {
            return Strings.allPlatforms
        }
        let name = selectedPlatforms.map { $0.name.capitalized }.joined(separator: ", ")
        return name
    }
}
