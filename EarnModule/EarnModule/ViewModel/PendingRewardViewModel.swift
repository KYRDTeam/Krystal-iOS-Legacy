//
//  PendingRewardViewModel.swift
//  EarnModule
//
//  Created by Ta Minh Quan on 12/12/2022.
//

import Foundation
import Services
import AppState

struct RewardItem {
    let rewardToken: RewardToken
    let chain: Chain
    let platform: RewardPlatform
}

class PendingRewardViewModel {
    let apiService = EarnServices()
    var searchText = ""
    var rewardData: [RewardItem] = []
    var chainID: Int?
    var dataSource: Observable<[PendingRewardCellModel]> = .init([])
    var isLoading: Observable<Bool> = .init(true)
    
    func reloadDataSource() {
        dataSource.value.removeAll()
        
        var data = rewardData
        
        if let chainID = chainID {
            data = data.filter({ item in
                return item.chain.id == chainID
            })
        }
        
        if !searchText.isEmpty {
            data = data.filter({ item in
                return item.rewardToken.tokenInfo.symbol.lowercased().contains(searchText)
            })
        }
        let cellModels = data.map { PendingRewardCellModel(item: $0) }
        dataSource.value = cellModels
    }
    
    func requestData() {
        isLoading.value = true
        apiService.getPendingReward(address: AppState.shared.currentAddress.addressString) { result in
            switch result {
            case .success(let rewards):
                var items: [RewardItem] = []
                rewards.forEach { element in
                    element.earningRewards.forEach { earningItem in
                        earningItem.rewardTokens?.forEach({ tokenItem in
                            let rewardItem = RewardItem(rewardToken: tokenItem, chain: earningItem.chain, platform: element.platform)
                            items.append(rewardItem)
                        })
                    }
                }
                self.rewardData = items
                self.reloadDataSource()
            case .failure(let error):
                print(error.description)
            }
            self.isLoading.value = false
        }
    }
}
