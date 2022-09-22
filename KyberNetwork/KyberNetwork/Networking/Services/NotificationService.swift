//
//  NotificationService.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 14/09/2022.
//

import Foundation
import Moya

class NotificationService {

  let provider = MoyaProvider<NotificationEndpoint>(plugins: [NetworkLoggerPlugin(verbose: true)])
  
  func getListNotification(type: NotificationType?, page: Int, limit: Int, status: NotificationStatus?, userAddress: String, completion: @escaping (NotificationResponseV2?) -> ()) {
    provider.requestWithFilter(.list(type: type, page: page, limit: limit, status: status, userAddress: userAddress)) { result in
      switch result {
      case .success(let response):
        let notificationResponse = try? JSONDecoder().decode(NotificationResponseV2.self, from: response.data)
        completion(notificationResponse)
      case .failure:
        completion(nil)
      }
    }
  }
  
  func read(ids: [Int], address: String) {
    provider.requestWithFilter(.read(ids: ids, address: address)) { _ in }
  }
  
  func readAll(type: NotificationType?, address: String) {
    provider.requestWithFilter(.readAll(type: type, address: address)) { _ in }
  }
  
}
