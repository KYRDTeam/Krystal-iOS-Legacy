//
//  NotificationEndpoint.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 14/09/2022.
//

import Foundation
import Moya

enum NotificationType: String {
  case news
}

enum NotificationStatus: String {
  case read
  case unread
  
  init(value: String) {
    switch value {
    case "read":
      self = .read
    default:
      self = .unread
    }
  }
}

enum NotificationEndpoint {
  case list(type: NotificationType?, page: Int, limit: Int, status: NotificationStatus?, userAddress: String)
}

extension NotificationEndpoint: TargetType {
  
  var baseURL: URL {
    return URL(string: KNEnvironment.default.notificationAPIURL)!
  }
  
  var path: String {
    switch self {
    case .list:
      return "/v1/notifications"
    }
  }
  
  var method: Moya.Method {
    switch self {
    case .list:
      return .get
    }
  }
  
  var sampleData: Data {
    return Data()
  }
  
  var task: Task {
    switch self {
    case .list(let type, let page, let limit, let status, let userAddress):
      var params: [String: Any] = [:]
      params["type"] = type?.rawValue
      params["page"] = page
      params["limit"] = limit
      params["status"] = status?.rawValue
      params["userAddress"] = userAddress
      return .requestParameters(parameters: params, encoding: URLEncoding.default)
    }
  }
  
  var headers: [String: String]? {
    switch self {
    case .list(_, _, _, _, let userAddress):
      let token = UserDefaults.standard.getAuthToken(address: userAddress) ?? ""
      return ["Authorization": "Bearer \(token)"]
    }
  }
  
}
