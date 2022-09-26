//
//  NotificationItemViewModel.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 14/09/2022.
//

import Foundation

class NotificationItemViewModel {
  var id: Int
  var icon: String
  var title: String
  var timeString: String
  var content: String
  var isRead: Bool
  var url: String
  
  init(notification: NotificationModel) {
    self.id = notification.id
    self.icon = notification.imageURL
    self.title = notification.title
    self.content = notification.content
    self.isRead = NotificationStatus(value: notification.status) == .read
    self.timeString = NotificationItemViewModel.getTimeString(time: notification.createdTime)
    self.url = notification.url
  }
  
  static func getTimeString(time: String) -> String {
    guard let updateDate = DateFormatterUtil.shared.notificationV2DateFormatter.date(from: time) else { return "" }
    let now = Date()
    let dayInterval = now.days(from: updateDate)
    if dayInterval >= 3 {
      return DateFormatterUtil.shared.notificationV2DisplayDateFormatter.string(from: updateDate)
    }
    if dayInterval == 2 {
      return String(format: Strings.xDaysAgo, dayInterval)
    } else if dayInterval == 1 {
      return Strings.oneDayAgo
    } else {
      return DateFormatterUtil.shared.todayTimeFormatter.string(from: updateDate)
    }
  }
  
}
