//
//  PortfolioViewModel.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 07/07/2022.
//

import Foundation
import RxRelay
import NSObject_Rx
import RxSwift
import RealmSwift

class PortfolioViewModel: ViewModel, ViewModelType {
  
  enum PortfolioPage {
    case asset
    case supply
    case liquidityPool
    case nft
    case market
    case favorite
  }
  
  let dataSource = PortfolioDataSource.dataSource()
  let currencyMode = BehaviorRelay<CurrencyMode>(value: .usd)
  let selectedPage = BehaviorRelay<PortfolioPage>(value: .asset)
  let assets = BehaviorRelay<[KTokenObject]>(value: [])
  let lendingPlatformBalances = BehaviorRelay<[LendingPlatformBalance]>(value: [])
  let lendingDistributionBalances = BehaviorRelay<[LendingDistributionBalance]>(value: [])
  let liquidityPools = BehaviorRelay<[LPTokenModel]>(value: [])
  let nfts = BehaviorRelay<[NFTItem]>(value: [])
  let marketTokens = BehaviorRelay<[TokenObject]>(value: [])
  let favoriteTokens = BehaviorRelay<[TokenObject]>(value: [])
  
  var notificationToken: NotificationToken?
  
  struct Input {
    
  }
  
  struct Output {
    var selectedPage: BehaviorRelay<PortfolioPage>
    var sections: BehaviorRelay<[PortfolioSectionModel]>
  }
  
  func transform(input: Input) -> Output {
    let sections = BehaviorRelay<[PortfolioSectionModel]>(value: [])

//    notificationToken = TokenPriceManager.shared.realm
//      .objects(KTokenObject.self)
////      .filter("compoundPrimaryKey")
//      .observe{ [weak self] change in
//        switch change {
//        case .update(let tokens, _, _, _):
//          self?.assets.accept(Array(tokens))
//        default:
//          ()
//        }
//      }
//    
    assets.accept(Array(TokenPriceManager.shared.realm.objects(KTokenObject.self)))
    
    Observable
      .combineLatest(
        selectedPage, assets, lendingPlatformBalances, lendingDistributionBalances, liquidityPools, nfts, marketTokens, favoriteTokens
      ) { page, assets, platformBalances, distBalances, pools, nfts, marketTokens, favoriteTokens -> [PortfolioSectionModel] in
        switch page {
        case .asset:
          return self.assetSections(fromAssets: assets)
        case .supply:
          return self.lendingSections(platformBalances: platformBalances, distBalances: distBalances)
        case .liquidityPool:
          return self.poolSections(pools: pools)
        case .nft:
          return self.nftSections(nfts: nfts)
        case .market:
          return self.marketSections(tokens: marketTokens)
        case .favorite:
          return self.favoriteSections(tokens: favoriteTokens)
        }
      }
      .bind(to: sections)
      .disposed(by: rx.disposeBag)
    
    return Output(selectedPage: selectedPage, sections: sections)
  }
  
  private func assetSections(fromAssets assets: [KTokenObject]) -> [PortfolioSectionModel] {
    let items = assets.map { token in
      PortfolioSectionItem.asset(token: token)
    }
    return [.assets(items: items)]
  }
  
  private func lendingSections(platformBalances: [LendingPlatformBalance], distBalances: [LendingDistributionBalance]) -> [PortfolioSectionModel] {
    let lendingDictionary = Dictionary(grouping: platformBalances) { $0.name }
    let lendingSections = lendingDictionary.keys.map { key -> PortfolioSectionModel in
      let items = lendingDictionary[key]?.flatMap { lendingPlatformBalance in
        return lendingPlatformBalance.balances.map {
          PortfolioSectionItem.lending(balance: $0)
        }
      }
      return PortfolioSectionModel.supply(title: key, items: items ?? [])
    }
    let lendingDistItems = distBalances.map { balance in
      PortfolioSectionItem.lendingDist(balance: balance)
    }
    return lendingSections + [.supply(title: Strings.other.uppercased(), items: lendingDistItems)]
  }
  
  private func poolSections(pools: [LPTokenModel]) -> [PortfolioSectionModel] {
    return []
  }
  
  private func nftSections(nfts: [NFTItem]) -> [PortfolioSectionModel] {
    return []
  }
  
  private func marketSections(tokens: [TokenObject]) -> [PortfolioSectionModel] {
    return []
  }
  
  private func favoriteSections(tokens: [TokenObject]) -> [PortfolioSectionModel] {
    return []
  }
  
}
