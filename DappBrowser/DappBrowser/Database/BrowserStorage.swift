//
//  BrowserStorage.swift
//  DappBrowser
//
//  Created by Tung Nguyen on 19/12/2022.
//

import Foundation
import Utilities

class BrowserItem: Codable, Equatable {
  var title: String
  var url: String
  var image: String?
  var timeStamp: Double
  
  init(title: String, url: String, image: String? = nil, time: Double = 0) {
    self.title = title
    self.url = url
    self.image = image
    self.timeStamp = time
  }
  
  static func == (lhs: BrowserItem, rhs: BrowserItem) -> Bool {
    return lhs.url.lowercased() == rhs.url.lowercased()
  }
}

class BrowserStorage {
  static let shared = BrowserStorage()
  
  var recentlyBrowser: [BrowserItem]
  var favoriteBrowser: [BrowserItem]
  
  init() {
    self.recentlyBrowser = Storage.retrieve(Constants.browserRecentlyFileName, as: [BrowserItem].self) ?? []
    self.favoriteBrowser = Storage.retrieve(Constants.browserFavoriteFileName, as: [BrowserItem].self) ?? []
  }
  
  func isFaved(url: String) -> Bool {
    let found = self.favoriteBrowser.first { element in
      return element.url == url
    }
    return found != nil
  }
  
  func addNewFavorite(item: BrowserItem) {
    self.favoriteBrowser.append(item)
    Storage.store(self.favoriteBrowser, as: Constants.browserFavoriteFileName)
  }
  
  func deleteFavoriteItem(_ input: BrowserItem) {
    if let index = self.favoriteBrowser.firstIndex(where: { item in
      return item == input
    }) {
      self.favoriteBrowser.remove(at: index)
    }
    Storage.store(self.favoriteBrowser, as: Constants.browserFavoriteFileName)
  }
  
  func isExistRecently(url: String) -> Bool {
    let found = self.recentlyBrowser.first { element in
      return element.url == url
    }
    return found != nil
  }
  
  func deleteRecentlyItem(_ input: BrowserItem) {
    if let index = self.recentlyBrowser.firstIndex(where: { item in
      return item == input
    }) {
      self.recentlyBrowser.remove(at: index)
    }
    Storage.store(self.recentlyBrowser, as: Constants.browserRecentlyFileName)
  }
  
  func deleteAllRecentlyItem() {
    self.recentlyBrowser.removeAll()
    Storage.store(self.recentlyBrowser, as: Constants.browserRecentlyFileName)
  }
  
  func addNewRecently(item: BrowserItem) {
    self.recentlyBrowser.append(item)
    Storage.store(self.recentlyBrowser, as: Constants.browserRecentlyFileName)
  }
}
