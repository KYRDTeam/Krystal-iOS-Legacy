//
//  PortfolioSectionModel.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 07/07/2022.
//

import Foundation
import RxDataSources

enum PortfolioSectionModel: SectionModelType {
  typealias Item = PortfolioSectionItem
  
  case assets(items: [PortfolioSectionItem])
  case supply(title: String, items: [PortfolioSectionItem])
  case liquidityPool(title: String, items: [PortfolioSectionItem])
  case nft(name: String, collapsed: Bool, items: [PortfolioSectionItem])
  case market(items: [PortfolioSectionItem])
  case favorite(items: [PortfolioSectionItem])
  
  var items: [PortfolioSectionItem] {
    switch self {
    case .assets(let items):
      return items
    case .supply(_, let items):
      return items
    case .liquidityPool(_, let items):
      return items
    case .nft(_, _, let items):
      return items
    case .market(let items):
      return items
    case .favorite(let items):
      return items
    }
  }

  init(original: PortfolioSectionModel, items: [PortfolioSectionItem]) {
    switch original {
    case .assets:
      self = .assets(items: items)
    case .supply(let title, _):
      self = .supply(title: title, items: items)
    case .liquidityPool(let title, _):
      self = .liquidityPool(title: title, items: items)
    case .nft(let name, let collapsed, _):
      self = .nft(name: name, collapsed: collapsed, items: items)
    case .market(let items):
      self = .market(items: items)
    case .favorite(let items):
      self = .market(items: items)
    }
  }
  
}
