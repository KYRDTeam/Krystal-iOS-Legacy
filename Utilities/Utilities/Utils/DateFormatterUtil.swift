//
//  DateFormatterUtil.swift
//  Utilities
//
//  Created by Tung Nguyen on 22/11/2022.
//

import Foundation

public class DateFormatterUtil {

  public static let shared = DateFormatterUtil()

    public lazy var MMMMddYYYY: DateFormatter = {
      let formatter = DateFormatter()
      formatter.locale = Locale(identifier: "en_US_POSIX")
      formatter.dateFormat = "MMMM dd, YYYY"
      return formatter
    }()
    
  public lazy var MMMddYYYHHmma: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "MMMM dd, YYYY HH:mm a"
    return formatter
  }()
  
  public lazy var priceAlertAPIFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
    return formatter
  }()

  public lazy var kycDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
  }()

  public lazy var backupDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd_HH:mm"
    return formatter
  }()

  public lazy var promoCodeDateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
    return dateFormatter
  }()

  public lazy var leaderBoardFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "dd MMM yyyy HH:mm"
    return dateFormatter
  }()

  public lazy var limitOrderFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "dd MMM yyyy"
    return dateFormatter
  }()

  public lazy var chartViewDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm"
    return formatter
  }()
   
  public lazy var historyTransactionDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "hh:mm a"
    return formatter
  }()
  
  public lazy var notificationDisplayDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "dd MMM yyyy"
    return formatter
  }()
  
  public lazy var notificationV2DisplayDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM dd"
    return formatter
  }()
  
  public lazy var notificationDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z"
    return formatter
  }()
  
  public lazy var notificationV2DateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z"
    formatter.timeZone = TimeZone(identifier: "GMT")
    return formatter
  }()
  
  public lazy var rewardDateTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    formatter.dateFormat = "HH:mm a dd MMM yyyy"
    return formatter
  }()
  
  public lazy var todayTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    formatter.locale = .current
    formatter.dateFormat = "HH:mm"
    return formatter
  }()
}
