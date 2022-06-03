// Copyright SIX DAY LLC. All rights reserved.

import Foundation

class DateFormatterUtil {

  static let shared = DateFormatterUtil()

  lazy var MMMddYYYHHmma: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "MMMM dd, YYYY HH:mm a"
    return formatter
  }()
  
  lazy var priceAlertAPIFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
    return formatter
  }()

  lazy var kycDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
  }()

  lazy var backupDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd_HH:mm"
    return formatter
  }()

  lazy var promoCodeDateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
    return dateFormatter
  }()

  lazy var leaderBoardFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "dd MMM yyyy HH:mm"
    return dateFormatter
  }()

  lazy var limitOrderFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "dd MMM yyyy"
    return dateFormatter
  }()

  lazy var chartViewDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm"
    return formatter
  }()
   
  lazy var historyTransactionDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "hh:mm a"
    return formatter
  }()
  
  lazy var notificationDisplayDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "dd MMM yyyy"
    return formatter
  }()
  
  lazy var notificationDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z"
    return formatter
  }()
  
  lazy var rewardDateTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    formatter.dateFormat = "HH:mm a dd MMM yyyy"
    return formatter
  }()
}
