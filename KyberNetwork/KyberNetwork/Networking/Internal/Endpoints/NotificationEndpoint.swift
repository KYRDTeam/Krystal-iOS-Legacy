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
    return URL(string: "https://notification-api-dev.krystal.team")!
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
    return ["Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2NjU1NjMxNjEsImp0aSI6IjB4OEQ2MWFCNzU3MWIxMTc2NDRBNTIyNDA0NTZERjY2RUY4NDZjZDk5OSJ9.qFHh5fz-rxc--RiIctNJ3Mibt8NoDIlYijay1tmhHJ0"]
  }
  
}
