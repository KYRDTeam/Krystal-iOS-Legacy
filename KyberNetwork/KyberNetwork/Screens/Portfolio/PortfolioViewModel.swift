//
//  PortfolioViewModel.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 07/07/2022.
//

import Foundation
import RxRelay
import NSObject_Rx

class PortfolioViewModel: ViewModel, ViewModelType {
  
  enum PortfolioPage {
    case asset
    case supply
    case liquidityPool
    case nft
    case market
    case favorite
  }
  
  let currencyMode = BehaviorRelay<CurrencyMode>(value: .usd)
  let selectedPage = BehaviorRelay<PortfolioPage>(value: .asset)
  let assets = BehaviorRelay<[Token]>(value: [])
  let lendingPlatformBalances = BehaviorRelay<[LendingPlatformBalance]>(value: [])
  let lendingDistributionBalances = BehaviorRelay<[LendingDistributionBalance]>(value: [])
  
  struct Input {
    
  }
  
  struct Output {
    var selectedPage: BehaviorRelay<PortfolioPage>
    var sections: BehaviorRelay<[PortfolioSectionModel]>
  }
  
  func transform(input: Input) -> Output {
    let sections = BehaviorRelay<[PortfolioSectionModel]>(value: [])
    
    selectedPage
      .subscribe(onNext: { [weak self] page in
        guard let self = self else { return }
        switch page {
        case .asset:
          let items = self.assets.value.map { token in
            PortfolioSectionItem.asset(token: token, price: 0)
          }
          sections.accept([.assets(items: items)])
        case .supply:
          let lendingDictionary = Dictionary(grouping: self.lendingPlatformBalances.value) { $0.name }
          let lendingSections = lendingDictionary.keys.map { key -> PortfolioSectionModel in
            let items = lendingDictionary[key]?.flatMap { platformLendingBalance in
              return platformLendingBalance.balances.map {
                PortfolioSectionItem.lending(balance: $0)
              }
            }
            return PortfolioSectionModel.supply(title: key, items: items ?? [])
          }
          let lendingDistItems = self.lendingDistributionBalances.value.map { balance in
            PortfolioSectionItem.lendingDist(balance: balance)
          }
          sections.accept(lendingSections + [.supply(title: Strings.other.uppercased(), items: lendingDistItems)])
        case .liquidityPool:
          return
        case .nft:
          return
        case .market:
          return
        case .favorite:
          return
        }
      })
      .disposed(by: rx.disposeBag)
    
    return Output(selectedPage: selectedPage, sections: sections)
  }
  
}
