//
//  NotificationListViewModel.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 14/09/2022.
//

import Foundation

class NotificationListViewModel {
  
  let service = NotificationService()
  var notifications: [NotificationItemViewModel] = []
  var canLoadMore: Bool = true
  var currentPage: Int = 1
  let pageSize = 20
  let type: NotificationType?
  let statusToFilter: NotificationStatus?
  var isLoading: Bool = false
  
  var address: String {
    return AppDelegate.session.address.addressString
  }
  
  init(type: NotificationType?, status: NotificationStatus?) {
    self.type = type
    self.statusToFilter = status
  }
  
  func reset() {
    self.canLoadMore = true
    self.currentPage = 1
    self.notifications = []
  }
  
  func load(reset: Bool, completion: @escaping () -> ()) {
    if reset { self.reset() }
    self.isLoading = true
    service.getListNotification(type: nil, page: currentPage, limit: pageSize, status: statusToFilter, userAddress: address) { [weak self] response in
      self?.isLoading = false
      guard let response = response else {
        self?.canLoadMore = false
        completion()
        return
      }
      let newItems = response.data.map(NotificationItemViewModel.init)
      if reset {
        self?.notifications = newItems
      } else {
        self?.notifications.append(contentsOf: newItems)
      }
      let canLoadMore = response.data.count == self?.pageSize
      self?.canLoadMore = canLoadMore
      self?.currentPage += (canLoadMore ? 1 : 0)
      completion()
    }
  }
  
}
