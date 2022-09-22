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
  case read(ids: [Int], address: String)
  case readAll(type: NotificationType?, address: String)
}

extension NotificationEndpoint: TargetType {
  
  var baseURL: URL {
    return URL(string: KNEnvironment.default.notificationAPIURL)!
  }
  
  var path: String {
    switch self {
    case .list:
      return "/v1/notifications"
    case .read:
      return "/v1/notifications/read"
    case .readAll:
      return "/v1/notifications/readAll"
    }
  }
  
  var method: Moya.Method {
    switch self {
    case .list:
      return .get
    case .read, .readAll:
      return .post
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
    case .read(let ids, _):
      let params = ["ids": ids]
      return .requestParameters(parameters: params, encoding: JSONEncoding.default)
    case .readAll(let type, _):
      var params: [String: Any] = [:]
      params["type"] = type?.rawValue
      return .requestParameters(parameters: params, encoding: JSONEncoding.default)
    }
  }
  
  var headers: [String: String]? {
    switch self {
    case .list(_, _, _, _, let address), .read(_, let address), .readAll(_, let address):
      let token = UserDefaults.standard.getAuthToken(address: address) ?? ""
      return ["Authorization": "Bearer \(token)", "Content-Type": "application/json"]
    }
  }
  
}
