//
//  AdvanceSearchTokenPresenter.swift
//  KyberNetwork
//
//  Created Com1 on 13/06/2022.
//  Copyright © 2022 ___ORGANIZATIONNAME___. All rights reserved.
//
//  Template generated by Juanpe Catalán @JuanpeCMiOS
//

import UIKit

class AdvanceSearchTokenPresenter: AdvanceSearchTokenPresenterProtocol {
  weak private var view: AdvanceSearchTokenViewProtocol?
  var interactor: AdvanceSearchTokenInteractorProtocol?
  private let router: AdvanceSearchTokenWireframeProtocol
  var isShowAll: Bool = false
  var searchResults: SearchResult?
  var currencyMode: CurrencyMode = .usd
  var recommendTags: [String] {
    return KNGeneralProvider.shared.currentChain.recommendTags()
  }

  func doSearch(keyword: String) {
    view?.showLoading()
    searchResults = nil
    interactor?.getSearchData(keyword: keyword)
  }

  func didGetSearchResult(result: SearchResult?, error: Error?) {
    view?.hideLoading()
    
    if let error = error, error.localizedDescription != Strings.cancelled {
      view?.showError(msg: error.localizedDescription)
    }
    
    guard let result = result else {
      searchResults = nil
      view?.reloadData()
      return
    }
    if result.tokens.isNotEmpty || result.portfolios.isNotEmpty {
      searchResults = result
    }
    view?.reloadData()
  }

  func numberOfRows(section: Int) -> Int {
    guard let dataSource = searchResults else {
      return 0
    }
    if section == 0 {
      return dataSource.portfolios.count
    } else if isShowAll {
      return dataSource.tokens.count + 1
    } else {
      return dataSource.tokens.count <= 10 ? dataSource.tokens.count : 11
    }
  }
  
  func shouldShowEmpty() -> Bool {
    guard let dataSource = searchResults else {
      return true
    }
    return dataSource.portfolios.isEmpty && dataSource.tokens.isEmpty
  }
  
  func getRecentSearchTag() -> [String] {
    if let tags = UserDefaults.standard.object(forKey: KNEnvironment.default.envPrefix + "Recent-search") as? [String] {
      return tags
    } else {
      return []
    }
  }
  
  func saveNewSearchTag(_ tag: String) {
    if var tags = UserDefaults.standard.object(forKey: KNEnvironment.default.envPrefix + "Recent-search") as? [String] {
      if !tags.contains(tag) {
        tags.append(tag)
        if tags.count > 8 {
          tags.remove(at: 0)
        }
        UserDefaults.standard.setValue(tags, forKey: KNEnvironment.default.envPrefix + "Recent-search")
      }
    } else {
      UserDefaults.standard.setValue([tag], forKey: KNEnvironment.default.envPrefix + "Recent-search")
    }
  }
  
  func openChartToken(token: ResultToken) {
    Tracker.track(event: .marketOpenDetail)
    router.openChartTokenView(token: token, currencyMode: self.currencyMode)
  }

  init(interface: AdvanceSearchTokenViewProtocol, interactor: AdvanceSearchTokenInteractorProtocol?, router: AdvanceSearchTokenWireframeProtocol) {
      self.view = interface
      self.interactor = interactor
      self.router = router
  }

}
